# Fase 1: Unificar estados de cuentas prop firm
# Mapeo de datos:
#   status "activa" + phase "paso_1/paso_2/express/sim" → status "evaluacion"
#   status "activa" + phase "fondeada"                  → status "fondeada"
#   status "fondeada"                                    → status "fondeada"
#   status "reseteada"                                   → status "evaluacion"
#   status "pausada"                                     → status "evaluacion"
#   status "quemada"                                     → status "quemada" (sin cambio)
#
# El campo `phase` se conserva solo para paso_1/paso_2 en evaluación.
# Se agrega `sim` como booleano aparte.
# Se agrega `funded_at` y `burned_at` para fechas de transición.
class RefactorPropFirmAccountStates < ActiveRecord::Migration[8.1]
  def up
    # Agregar nuevos campos
    add_column :prop_firm_accounts, :funded_at, :date
    add_column :prop_firm_accounts, :burned_at, :date
    add_column :prop_firm_accounts, :sim, :boolean, default: false, null: false

    # Migración de datos: mapear estados actuales al nuevo esquema
    execute <<~SQL
      -- Cuentas "activa" con phase "fondeada" → status "fondeada"
      UPDATE prop_firm_accounts
      SET status = 'fondeada', phase = NULL
      WHERE status = 'activa' AND phase = 'fondeada';

      -- Cuentas "activa" con phase "sim" → status "evaluacion", sim = true
      UPDATE prop_firm_accounts
      SET status = 'evaluacion', sim = 1, phase = NULL
      WHERE status = 'activa' AND phase = 'sim';

      -- Cuentas "activa" con phase "express" → status "evaluacion", phase NULL
      UPDATE prop_firm_accounts
      SET status = 'evaluacion', phase = NULL
      WHERE status = 'activa' AND phase = 'express';

      -- Cuentas "activa" con phase "paso_1" o "paso_2" → status "evaluacion"
      UPDATE prop_firm_accounts
      SET status = 'evaluacion'
      WHERE status = 'activa' AND phase IN ('paso_1', 'paso_2');

      -- Cuentas "fondeada" (ya están correctas, limpiar phase)
      UPDATE prop_firm_accounts
      SET phase = NULL
      WHERE status = 'fondeada';

      -- Cuentas "reseteada" → status "evaluacion", phase "paso_1"
      UPDATE prop_firm_accounts
      SET status = 'evaluacion', phase = 'paso_1'
      WHERE status = 'reseteada';

      -- Cuentas "pausada" → status "evaluacion"
      UPDATE prop_firm_accounts
      SET status = 'evaluacion'
      WHERE status = 'pausada';

      -- Registrar funded_at para cuentas ya fondeadas (aprox con updated_at)
      UPDATE prop_firm_accounts
      SET funded_at = DATE(updated_at)
      WHERE status = 'fondeada' AND funded_at IS NULL;

      -- Registrar burned_at para cuentas ya quemadas
      UPDATE prop_firm_accounts
      SET burned_at = DATE(updated_at)
      WHERE status = 'quemada' AND burned_at IS NULL;
    SQL

    # Cambiar default de status
    change_column_default :prop_firm_accounts, :status, from: "activa", to: "evaluacion"

    # Hacer phase nullable (ya no es NOT NULL)
    change_column_null :prop_firm_accounts, :phase, true
  end

  def down
    # Revertir migración de datos
    execute <<~SQL
      UPDATE prop_firm_accounts
      SET status = 'activa'
      WHERE status = 'evaluacion';
    SQL

    change_column_default :prop_firm_accounts, :status, from: "evaluacion", to: "activa"
    change_column_null :prop_firm_accounts, :phase, false, "paso_1"

    remove_column :prop_firm_accounts, :funded_at
    remove_column :prop_firm_accounts, :burned_at
    remove_column :prop_firm_accounts, :sim
  end
end
