# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_23_135100) do
  create_table "ai_analyses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "discipline_score"
    t.text "feedback"
    t.string "pattern_detected"
    t.text "reflection_question"
    t.integer "trade_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["trade_id"], name: "index_ai_analyses_on_trade_id"
    t.index ["user_id"], name: "index_ai_analyses_on_user_id"
  end

  create_table "ai_conversations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_ai_conversations_on_user_id"
  end

  create_table "ai_messages", force: :cascade do |t|
    t.integer "ai_conversation_id", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.index ["ai_conversation_id"], name: "index_ai_messages_on_ai_conversation_id"
  end

  create_table "backtest_sessions", force: :cascade do |t|
    t.decimal "account_size", precision: 12, scale: 2, default: "100000.0"
    t.string "asset"
    t.datetime "created_at", null: false
    t.date "end_date"
    t.decimal "max_daily_loss_pct", precision: 5, scale: 2, default: "2.0"
    t.decimal "max_drawdown_pct", precision: 5, scale: 2, default: "8.0"
    t.string "name", null: false
    t.text "notes"
    t.decimal "profit_target_pct", precision: 5, scale: 2, default: "8.0"
    t.string "prop_company"
    t.string "session_type", default: "backtest", null: false
    t.date "start_date"
    t.string "status", default: "active"
    t.integer "strategy_id"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_backtest_sessions_on_user_id"
  end

  create_table "brokers", force: :cascade do |t|
    t.text "autosync_instructions"
    t.string "category", default: "broker"
    t.datetime "created_at", null: false
    t.text "csv_instructions"
    t.string "logo_filename"
    t.string "name", null: false
    t.boolean "supports_autosync", default: false
    t.boolean "supports_file_upload", default: true
    t.boolean "supports_manual", default: true
    t.datetime "updated_at", null: false
  end

  create_table "chat_rooms", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "classrooms", force: :cascade do |t|
    t.integer "author_id", null: false
    t.string "category"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_classrooms_on_author_id"
  end

  create_table "comments", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.integer "post_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["post_id"], name: "index_comments_on_post_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "enrollments", force: :cascade do |t|
    t.integer "classroom_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["classroom_id"], name: "index_enrollments_on_classroom_id"
    t.index ["user_id"], name: "index_enrollments_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.integer "chat_room_id", null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["chat_room_id"], name: "index_messages_on_chat_room_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.string "category", default: "system"
    t.datetime "created_at", null: false
    t.text "message", null: false
    t.boolean "read", default: false, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "posts", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.string "status"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.string "visibility"
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "prop_firm_accounts", force: :cascade do |t|
    t.string "account_size", null: false
    t.decimal "activation_fee", precision: 10, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.decimal "custom_consistency_pct", precision: 5, scale: 2
    t.decimal "custom_daily_loss_limit", precision: 12, scale: 2
    t.string "custom_drawdown_type"
    t.decimal "custom_max_drawdown", precision: 12, scale: 2
    t.integer "custom_min_trading_days"
    t.decimal "custom_profit_target", precision: 12, scale: 2
    t.decimal "eval_fee", precision: 10, scale: 2, default: "0.0"
    t.string "firm_name", null: false
    t.string "name", null: false
    t.string "phase", null: false
    t.string "plan_name", null: false
    t.integer "prop_firm_rule_template_id"
    t.date "start_date"
    t.string "status", default: "activa", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["prop_firm_rule_template_id"], name: "index_prop_firm_accounts_on_prop_firm_rule_template_id"
    t.index ["user_id"], name: "index_prop_firm_accounts_on_user_id"
  end

  create_table "prop_firm_accounts_strategies", id: false, force: :cascade do |t|
    t.integer "prop_firm_account_id", null: false
    t.integer "strategy_id", null: false
    t.index ["prop_firm_account_id"], name: "idx_prop_accounts_strategies_pfa_id"
    t.index ["strategy_id"], name: "index_prop_firm_accounts_strategies_on_strategy_id"
  end

  create_table "prop_firm_rule_templates", force: :cascade do |t|
    t.string "account_size", null: false
    t.decimal "consistency_pct", precision: 5, scale: 2
    t.datetime "created_at", null: false
    t.decimal "daily_loss_limit", precision: 12, scale: 2
    t.decimal "default_activation_fee", precision: 10, scale: 2
    t.decimal "default_eval_fee", precision: 10, scale: 2
    t.string "drawdown_type", default: "eod", null: false
    t.string "firm_name", null: false
    t.integer "max_contracts"
    t.decimal "max_drawdown", precision: 12, scale: 2
    t.integer "min_trading_days", default: 0
    t.string "phase", null: false
    t.string "plan_name", null: false
    t.decimal "profit_target", precision: 12, scale: 2
    t.datetime "updated_at", null: false
    t.index ["firm_name", "plan_name", "account_size", "phase"], name: "idx_prop_rule_templates_uniqueness", unique: true
  end

  create_table "prop_transactions", force: :cascade do |t|
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.string "company_name", null: false
    t.datetime "created_at", null: false
    t.string "description"
    t.date "transaction_date", null: false
    t.string "transaction_type", default: "expense", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_prop_transactions_on_user_id"
  end

  create_table "reactions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "post_id", null: false
    t.string "reaction_type"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["post_id"], name: "index_reactions_on_post_id"
    t.index ["user_id"], name: "index_reactions_on_user_id"
  end

  create_table "resources", force: :cascade do |t|
    t.integer "author_id", null: false
    t.string "category"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "title"
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["author_id"], name: "index_resources_on_author_id"
  end

  create_table "review_requests", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "mentor_id", null: false
    t.text "message"
    t.integer "requester_id", null: false
    t.string "status"
    t.integer "trade_id", null: false
    t.datetime "updated_at", null: false
    t.index ["mentor_id"], name: "index_review_requests_on_mentor_id"
    t.index ["requester_id"], name: "index_review_requests_on_requester_id"
    t.index ["trade_id"], name: "index_review_requests_on_trade_id"
  end

  create_table "strategies", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "market"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "name"], name: "index_strategies_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_strategies_on_user_id"
  end

  create_table "trade_notes", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.integer "trade_id", null: false
    t.datetime "updated_at", null: false
    t.index ["trade_id"], name: "index_trade_notes_on_trade_id"
  end

  create_table "trade_shares", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "note"
    t.string "privacy"
    t.text "title"
    t.integer "trade_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["trade_id"], name: "index_trade_shares_on_trade_id"
    t.index ["user_id"], name: "index_trade_shares_on_user_id"
  end

  create_table "trades", force: :cascade do |t|
    t.decimal "capital_used", precision: 15, scale: 2
    t.decimal "commission", precision: 10, scale: 4, default: "0.0"
    t.datetime "created_at", null: false
    t.string "direction", null: false
    t.string "emotion"
    t.datetime "entry_at"
    t.decimal "entry_price", precision: 20, scale: 8
    t.text "entry_reason"
    t.datetime "exit_at"
    t.decimal "exit_price", precision: 20, scale: 8
    t.text "exit_reason"
    t.string "market"
    t.text "notes"
    t.decimal "pnl", precision: 15, scale: 2, null: false
    t.decimal "pnl_percent", precision: 8, scale: 4
    t.integer "portfolio_mode", default: 0, null: false
    t.decimal "position_size", precision: 20, scale: 8
    t.integer "prop_firm_account_id"
    t.decimal "r_multiple", precision: 8, scale: 2
    t.integer "rating"
    t.string "result"
    t.decimal "risk_amount", precision: 15, scale: 2
    t.string "screenshot_url"
    t.string "setup"
    t.decimal "stop_loss", precision: 20, scale: 8
    t.integer "strategy_id"
    t.string "symbol", null: false
    t.string "tags"
    t.decimal "take_profit", precision: 20, scale: 8
    t.string "timeframe"
    t.integer "trading_account_id"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["prop_firm_account_id"], name: "index_trades_on_prop_firm_account_id"
    t.index ["strategy_id"], name: "index_trades_on_strategy_id"
    t.index ["trading_account_id"], name: "index_trades_on_trading_account_id"
    t.index ["user_id", "entry_at"], name: "index_trades_on_user_id_and_entry_at"
    t.index ["user_id", "result"], name: "index_trades_on_user_id_and_result"
    t.index ["user_id", "symbol"], name: "index_trades_on_user_id_and_symbol"
    t.index ["user_id"], name: "index_trades_on_user_id"
  end

  create_table "trading_accounts", force: :cascade do |t|
    t.string "account_type", default: "real"
    t.string "api_key"
    t.string "api_secret"
    t.integer "broker_id"
    t.string "connection_method", default: "manual", null: false
    t.datetime "created_at", null: false
    t.string "date_format", default: "YYYY-MM-DD"
    t.datetime "last_synced_at"
    t.string "name", null: false
    t.integer "prop_firm_account_id"
    t.string "time_zone", default: "UTC"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["broker_id"], name: "index_trading_accounts_on_broker_id"
    t.index ["prop_firm_account_id"], name: "index_trading_accounts_on_prop_firm_account_id"
    t.index ["user_id"], name: "index_trading_accounts_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.decimal "initial_capital", precision: 15, scale: 2
    t.string "main_market"
    t.string "name", default: "", null: false
    t.boolean "onboarding_completed", default: false, null: false
    t.string "paypal_subscription_id"
    t.string "preferred_currency", default: "USD"
    t.boolean "pro_status", default: false, null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role", default: "user", null: false
    t.datetime "subscription_expires_at"
    t.string "timezone", default: "UTC"
    t.string "trader_type"
    t.string "trading_goal"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "ai_analyses", "trades"
  add_foreign_key "ai_analyses", "users"
  add_foreign_key "ai_conversations", "users"
  add_foreign_key "ai_messages", "ai_conversations"
  add_foreign_key "backtest_sessions", "users"
  add_foreign_key "classrooms", "users", column: "author_id"
  add_foreign_key "comments", "posts"
  add_foreign_key "comments", "users"
  add_foreign_key "enrollments", "classrooms"
  add_foreign_key "enrollments", "users"
  add_foreign_key "messages", "chat_rooms"
  add_foreign_key "messages", "users"
  add_foreign_key "notifications", "users"
  add_foreign_key "posts", "users"
  add_foreign_key "prop_firm_accounts", "prop_firm_rule_templates"
  add_foreign_key "prop_firm_accounts", "users"
  add_foreign_key "prop_transactions", "users"
  add_foreign_key "reactions", "posts"
  add_foreign_key "reactions", "users"
  add_foreign_key "resources", "users", column: "author_id"
  add_foreign_key "review_requests", "trades"
  add_foreign_key "review_requests", "users", column: "mentor_id"
  add_foreign_key "review_requests", "users", column: "requester_id"
  add_foreign_key "strategies", "users"
  add_foreign_key "trade_notes", "trades"
  add_foreign_key "trade_shares", "trades"
  add_foreign_key "trade_shares", "users"
  add_foreign_key "trades", "prop_firm_accounts"
  add_foreign_key "trades", "strategies"
  add_foreign_key "trades", "trading_accounts"
  add_foreign_key "trades", "users"
  add_foreign_key "trading_accounts", "brokers"
  add_foreign_key "trading_accounts", "prop_firm_accounts"
  add_foreign_key "trading_accounts", "users"
end
