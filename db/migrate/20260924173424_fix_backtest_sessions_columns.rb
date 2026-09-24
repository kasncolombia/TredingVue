class FixBacktestSessionsColumns < ActiveRecord::Migration[8.1]
  def change
    # ==========================================
    # 1. asset → symbol
    # ==========================================

    if column_exists?(:backtest_sessions, :asset) &&
       !column_exists?(:backtest_sessions, :symbol)
      rename_column :backtest_sessions, :asset, :symbol
    end

    # ==========================================
    # 2. status → state
    # ==========================================

    if column_exists?(:backtest_sessions, :status) &&
       !column_exists?(:backtest_sessions, :state)
      rename_column :backtest_sessions, :status, :state
    end

    # Convertir estados antiguos
    execute <<~SQL
      UPDATE backtest_sessions
      SET state = 'created'
      WHERE state = 'active'
    SQL

    # ==========================================
    # 3. account_size → balance_inicial
    # ==========================================

    if column_exists?(:backtest_sessions, :account_size) &&
       !column_exists?(:backtest_sessions, :balance_inicial)
      rename_column :backtest_sessions, :account_size, :balance_inicial
    end

    # ==========================================
    # 4. balance_actual
    # ==========================================

    unless column_exists?(:backtest_sessions, :balance_actual)
      add_column :backtest_sessions,
                 :balance_actual,
                 :decimal,
                 precision: 15,
                 scale: 2
    end

    # Inicializar balance_actual
    execute <<~SQL
      UPDATE backtest_sessions
      SET balance_actual = balance_inicial
      WHERE balance_actual IS NULL
    SQL

    # ==========================================
    # 5. Replay Engine
    # ==========================================

    unless column_exists?(:backtest_sessions, :timeframe)
      add_column :backtest_sessions,
                 :timeframe,
                 :string,
                 default: "M1"
    end

    unless column_exists?(:backtest_sessions, :speed)
      add_column :backtest_sessions,
                 :speed,
                 :integer,
                 default: 1
    end

    unless column_exists?(:backtest_sessions, :replay_cursor)
      add_column :backtest_sessions,
                 :replay_cursor,
                 :datetime
    end

    unless column_exists?(:backtest_sessions, :config)
      add_column :backtest_sessions,
                 :config,
                 :json,
                 default: {}
    end

    # ==========================================
    # 6. Índices
    # ==========================================

    unless index_exists?(:backtest_sessions, :symbol)
      add_index :backtest_sessions, :symbol
    end

    unless index_exists?(:backtest_sessions, :state)
      add_index :backtest_sessions, :state
    end
  end
end