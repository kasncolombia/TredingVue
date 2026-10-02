require_relative "../test_helper"

class PropFirmAccountTest < ActiveSupport::TestCase
  def setup
    @user = users(:one) rescue User.first
    unless @user
      @user = User.create!(
        email: "test_prop@example.com",
        password: "password123",
        name: "Test Trader"
      )
    end

    @account = PropFirmAccount.new(
      user: @user,
      name: "Test Topstep 50K",
      firm_name: "Topstep",
      plan_name: "Trading Combine",
      account_size: "50K",
      status: "evaluacion",
      phase: "paso_1",
      eval_fee: 49.0,
      activation_fee: 149.0,
      start_date: Date.current
    )
  end

  # ══════════════════════════════════════════
  # TESTS DE VALIDACIÓN
  # ══════════════════════════════════════════

  test "cuenta válida se guarda correctamente" do
    assert @account.valid?, @account.errors.full_messages.join(", ")
  end

  test "status debe ser uno de los valores permitidos" do
    @account.status = "activa" # valor viejo
    assert_not @account.valid?
    assert_includes @account.errors[:status], "is not included in the list"
  end

  test "status evaluacion es válido" do
    @account.status = "evaluacion"
    assert @account.valid?
  end

  test "status fondeada es válido" do
    @account.status = "fondeada"
    @account.phase = nil # fondeada no tiene phase
    assert @account.valid?
  end

  test "phase solo aplica en evaluación" do
    @account.status = "fondeada"
    @account.phase = "paso_1"
    assert_not @account.valid?
    assert_includes @account.errors[:phase], "solo aplica cuando la cuenta está en evaluación"
  end

  test "burn_reason es obligatorio cuando status es quemada" do
    @account.status = "quemada"
    @account.phase = nil
    @account.burn_reason = nil
    assert_not @account.valid?
    assert_includes @account.errors[:burn_reason], "can't be blank"
  end

  test "burn_reason no es obligatorio cuando status no es quemada" do
    @account.status = "evaluacion"
    @account.burn_reason = nil
    assert @account.valid?
  end

  # ══════════════════════════════════════════
  # TESTS DE initial_balance (BUG FIX)
  # ══════════════════════════════════════════

  test "initial_balance con formato 50K devuelve 50000" do
    @account.account_size = "50K"
    assert_equal 50_000.0, @account.initial_balance
  end

  test "initial_balance con formato 100K devuelve 100000" do
    @account.account_size = "100K"
    assert_equal 100_000.0, @account.initial_balance
  end

  test "initial_balance con formato 150K devuelve 150000" do
    @account.account_size = "150K"
    assert_equal 150_000.0, @account.initial_balance
  end

  test "initial_balance con formato numérico 50000 devuelve 50000" do
    @account.account_size = "50000"
    assert_equal 50_000.0, @account.initial_balance
  end

  test "initial_balance con 880000 NO devuelve 880 millones" do
    @account.account_size = "880000"
    # Antes del fix: 880000 * 1000 = 880_000_000 ❌
    # Después del fix: 880000 ✅ (pero falla validación de rango)
    assert_equal 880_000.0, @account.initial_balance
  end

  # ══════════════════════════════════════════
  # TESTS DE VALIDACIÓN DE RANGO
  # ══════════════════════════════════════════

  test "account_size fuera de rango rechazado" do
    @account.account_size = "2000000" # $2M fuera de rango
    assert_not @account.valid?
  end

  test "account_size con rango válido aceptado" do
    @account.account_size = "50K"
    assert @account.valid?
  end

  # ══════════════════════════════════════════
  # TESTS DE TRANSICIONES DE ESTADO
  # ══════════════════════════════════════════

  test "pasar_a_fondeada! transiciona de evaluacion a fondeada" do
    @account.save!
    @account.pasar_a_fondeada!
    @account.reload

    assert_equal "fondeada", @account.status
    assert_nil @account.phase
    assert_equal Date.current, @account.funded_at
  end

  test "pasar_a_fondeada! falla si no está en evaluación" do
    @account.save!
    @account.update_columns(status: "quemada", burn_reason: "Overtrading", phase: nil)

    assert_raises(RuntimeError) { @account.pasar_a_fondeada! }
  end

  test "pasar_a_fondeada! crea transacción de activación si hay costo" do
    @account.save!
    
    assert_difference "PropTransaction.count", 1 do
      @account.pasar_a_fondeada!(costo_activacion: 149.0)
    end

    tx = PropTransaction.last
    assert_equal "expense", tx.transaction_type
    assert_equal 149.0, tx.amount.to_f
    assert_equal @account.id, tx.prop_firm_account_id
  end

  test "quemar! transiciona a quemada con motivo" do
    @account.save!
    @account.quemar!(motivo: "Drawdown máximo")
    @account.reload

    assert_equal "quemada", @account.status
    assert_equal "Drawdown máximo", @account.burn_reason
    assert_equal Date.current, @account.burned_at
  end

  test "quemar! falla sin motivo" do
    @account.save!
    assert_raises(RuntimeError) { @account.quemar!(motivo: nil) }
  end

  test "quemar! falla si ya está quemada" do
    @account.save!
    @account.update_columns(status: "quemada", burn_reason: "Overtrading", phase: nil)

    assert_raises(RuntimeError) { @account.quemar!(motivo: "Otro") }
  end

  test "resetear! transiciona de quemada a evaluacion" do
    @account.save!
    @account.update_columns(status: "quemada", burn_reason: "Overtrading", phase: nil)

    @account.resetear!(costo_reset: 50.0)
    @account.reload

    assert_equal "evaluacion", @account.status
    assert_equal "paso_1", @account.phase
    assert_nil @account.burn_reason
    assert_nil @account.burned_at
  end

  test "resetear! crea transacción de gasto si hay costo" do
    @account.save!
    @account.update_columns(status: "quemada", burn_reason: "Overtrading", phase: nil)

    assert_difference "PropTransaction.count", 1 do
      @account.resetear!(costo_reset: 50.0)
    end

    tx = PropTransaction.last
    assert_equal "expense", tx.transaction_type
    assert_equal 50.0, tx.amount.to_f
  end

  test "resetear! falla si no está quemada" do
    @account.save!
    assert_raises(RuntimeError) { @account.resetear! }
  end

  test "cerrar! transiciona de fondeada a cerrada" do
    @account.save!
    @account.update_columns(status: "fondeada", phase: nil)

    @account.cerrar!
    @account.reload

    assert_equal "cerrada", @account.status
  end

  test "cerrar! falla si está en evaluación" do
    @account.save!
    assert_raises(RuntimeError) { @account.cerrar! }
  end

  # ══════════════════════════════════════════
  # TESTS DE PREDICADOS
  # ══════════════════════════════════════════

  test "evaluacion? retorna true cuando status es evaluacion" do
    @account.status = "evaluacion"
    assert @account.evaluacion?
  end

  test "fondeada? retorna true cuando status es fondeada" do
    @account.status = "fondeada"
    assert @account.fondeada?
  end

  test "quemada? retorna true cuando status es quemada" do
    @account.status = "quemada"
    assert @account.quemada?
  end

  # ══════════════════════════════════════════
  # TESTS DE ETIQUETAS UI
  # ══════════════════════════════════════════

  test "status_label devuelve texto en español" do
    @account.status = "evaluacion"
    assert_equal "Evaluación", @account.status_label

    @account.status = "fondeada"
    assert_equal "Fondeada", @account.status_label
  end

  test "phase_label devuelve nil si no está en evaluación" do
    @account.status = "fondeada"
    @account.phase = nil
    assert_nil @account.phase_label
  end

  test "phase_label devuelve texto formateado" do
    @account.status = "evaluacion"
    @account.phase = "paso_1"
    assert_equal "Paso 1", @account.phase_label
  end

  # ══════════════════════════════════════════
  # TESTS DE COMPATIBILIDAD LEGACY
  # ══════════════════════════════════════════

  test "mark_as_burned! es alias de quemar!" do
    @account.save!
    @account.mark_as_burned!("Overtrading")
    assert_equal "quemada", @account.reload.status
  end

  test "move_to_funded! es alias de pasar_a_fondeada!" do
    @account.save!
    @account.move_to_funded!(0)
    assert_equal "fondeada", @account.reload.status
  end

  test "reset_account! es alias de resetear!" do
    @account.save!
    @account.update_columns(status: "quemada", burn_reason: "Overtrading", phase: nil)
    @account.reset_account!(0)
    assert_equal "evaluacion", @account.reload.status
  end
end
