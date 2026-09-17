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

ActiveRecord::Schema[8.1].define(version: 2026_09_17_000002) do
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
    t.decimal "position_size", precision: 20, scale: 8
    t.decimal "r_multiple", precision: 8, scale: 2
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
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["strategy_id"], name: "index_trades_on_strategy_id"
    t.index ["user_id", "entry_at"], name: "index_trades_on_user_id_and_entry_at"
    t.index ["user_id", "result"], name: "index_trades_on_user_id_and_result"
    t.index ["user_id", "symbol"], name: "index_trades_on_user_id_and_symbol"
    t.index ["user_id"], name: "index_trades_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.decimal "initial_capital", precision: 15, scale: 2
    t.string "main_market"
    t.string "name", default: "", null: false
    t.boolean "onboarding_completed", default: false, null: false
    t.string "preferred_currency", default: "USD"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role", default: "user", null: false
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
  add_foreign_key "classrooms", "users", column: "author_id"
  add_foreign_key "comments", "posts"
  add_foreign_key "comments", "users"
  add_foreign_key "enrollments", "classrooms"
  add_foreign_key "enrollments", "users"
  add_foreign_key "messages", "chat_rooms"
  add_foreign_key "messages", "users"
  add_foreign_key "notifications", "users"
  add_foreign_key "posts", "users"
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
  add_foreign_key "trades", "strategies"
  add_foreign_key "trades", "users"
end
