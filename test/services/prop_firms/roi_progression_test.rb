require_relative "../../test_helper"

class PropFirms::RoiProgressionTest < ActiveSupport::TestCase
  def setup
    @user = users(:one) rescue User.first
    unless @user
      @user = User.create!(
        email: "test_roi@example.com",
        password: "password123",
        name: "Test Trader"
      )
    end
    # Limpiamos txs para la prueba
    @user.prop_transactions.destroy_all
  end

  test "devuelve Dataset A (modo demo) cuando no hay transacciones reales" do
    result = PropFirms::RoiProgression.call(user: @user)
    
    assert_equal ["23 feb","02 mar","12 mar","25 mar","14 abr","08 may","12 jun","26 jun","29 jun","01 jul","06 jul","10 jul"], result[:labels]
    assert_equal [150, 300, 350, 250, 250, 3300, 3900, 4100, 4050, 4200, 4150, 5350], result[:ingresos]
    assert_equal [150, 350, 400, 650, 1050, 900, 800, 1100, 1400, 1500, 1550, 1550], result[:gastos]
    assert_equal [150, 100, 0, -100, -600, 2000, 3200, 3500, 3250, 3400, 3250, 4300], result[:retorno]
  end

  test "calcula correctamente acumulados del Dataset B" do
    # Simular las 12 transacciones exactas que dan los montos acumulados esperados:
    [
      { date: "2026-02-23", type: "expense", amount: 49 },
      { date: "2026-03-02", type: "expense", amount: 49 }, # acumulado 98
      { date: "2026-03-12", type: "expense", amount: 49 }, # acumulado 147
      { date: "2026-03-25", type: "expense", amount: 149 }, # acumulado 296
      { date: "2026-04-14", type: "expense", amount: 349 }, # acumulado 645
      { date: "2026-05-08", type: "payout", amount: 1500 }, # acumulado ingresos 1500, gastos 645
      { date: "2026-06-12", type: "payout", amount: 1200 }, # acumulado ingresos 2700, gastos 645
      { date: "2026-06-26", type: "payout", amount: 1200 }, # acumulado ingresos 3900, gastos 645
      { date: "2026-06-29", type: "expense", amount: 344 }, # acumulado ingresos 3900, gastos 989
      { date: "2026-07-01", type: "expense", amount: 49 }, # acumulado ingresos 3900, gastos 1038
      { date: "2026-07-06", type: "expense", amount: 49 }, # acumulado ingresos 3900, gastos 1087
      { date: "2026-07-10", type: "payout", amount: 1100 } # acumulado ingresos 5000, gastos 1087
    ].each do |tx|
      @user.prop_transactions.create!(
        company_name: "Mock Firm",
        transaction_type: tx[:type],
        amount: tx[:amount],
        transaction_date: Date.parse(tx[:date])
      )
    end

    result = PropFirms::RoiProgression.call(user: @user)

    assert_equal ["23 feb", "02 mar", "12 mar", "25 mar", "14 abr", "08 may", "12 jun", "26 jun", "29 jun", "01 jul", "06 jul", "10 jul"], result[:labels]
    assert_equal [0, 0, 0, 0, 0, 1500, 2700, 3900, 3900, 3900, 3900, 5000], result[:ingresos]
    assert_equal [49, 98, 147, 296, 645, 645, 645, 645, 989, 1038, 1087, 1087], result[:gastos]
    assert_equal [-49, -98, -147, -296, -645, 855, 2055, 3255, 2911, 2862, 2813, 3913], result[:retorno]
  end
end
