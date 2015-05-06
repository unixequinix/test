# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150505180300) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "admins", force: :cascade do |t|
    t.string   "email",                  default: "", null: false, index: {name: "index_admins_on_email", unique: true}
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token",   index: {name: "index_admins_on_reset_password_token", unique: true}
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "customers", force: :cascade do |t|
    t.string   "email",                  default: "", null: false, index: {name: "index_customers_on_email", unique: true}
    t.string   "name",                   default: "", null: false
    t.string   "surname",                default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token",   index: {name: "index_customers_on_reset_password_token", unique: true}
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "ticket_types", force: :cascade do |t|
    t.string   "name",       null: false
    t.string   "company",    null: false
    t.decimal  "credit",     precision: 8, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tickets", force: :cascade do |t|
    t.integer  "ticket_type_id", index: {name: "fk__tickets_ticket_type_id"}, foreign_key: {references: "ticket_types", name: "fk_tickets_ticket_type_id", on_update: :no_action, on_delete: :no_action}
    t.string   "number",         index: {name: "index_tickets_on_number", unique: true}
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  create_table "admissions", force: :cascade do |t|
    t.integer  "customer_id", null: false, index: {name: "fk__admissions_customer_id"}, foreign_key: {references: "customers", name: "fk_admissions_customer_id", on_update: :no_action, on_delete: :no_action}
    t.integer  "ticket_id",   null: false, index: {name: "index_admissions_on_ticket_id"}, foreign_key: {references: "tickets", name: "fk_admissions_ticket_id", on_update: :no_action, on_delete: :no_action}
    t.decimal  "credit",      precision: 8, scale: 2
    t.string   "aasm_state",  null: false
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "credit_logs", force: :cascade do |t|
    t.integer  "customer_id",      null: false, index: {name: "fk__credit_logs_customer_id"}, foreign_key: {references: "customers", name: "fk_credit_logs_customer_id", on_update: :no_action, on_delete: :no_action}
    t.string   "transaction_type"
    t.decimal  "amount",           precision: 8, scale: 2, null: false
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  create_table "credits", force: :cascade do |t|
    t.boolean  "standard",   default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "entitlements", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "entitlement_ticket_types", force: :cascade do |t|
    t.integer  "entitlement_id", null: false, index: {name: "fk__entitlement_ticket_types_entitlement_id"}, foreign_key: {references: "entitlements", name: "fk_entitlement_ticket_types_entitlement_id", on_update: :no_action, on_delete: :no_action}
    t.integer  "ticket_type_id", null: false, index: {name: "fk__entitlement_ticket_types_ticket_type_id"}, foreign_key: {references: "ticket_types", name: "fk_entitlement_ticket_types_ticket_type_id", on_update: :no_action, on_delete: :no_action}
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  create_table "events", force: :cascade do |t|
    t.string   "name"
    t.string   "aasm_state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string   "slug",           null: false, index: {name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", with: ["sluggable_type", "scope"], unique: true}
    t.integer  "sluggable_id",   null: false, index: {name: "index_friendly_id_slugs_on_sluggable_id"}
    t.string   "sluggable_type", limit: 50, index: {name: "index_friendly_id_slugs_on_sluggable_type"}
    t.string   "scope"
    t.datetime "created_at"
  end
  add_index "friendly_id_slugs", ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"

  create_table "online_products", force: :cascade do |t|
    t.string   "name",             null: false
    t.string   "description",      null: false
    t.decimal  "price",            precision: 8, scale: 2, null: false
    t.integer  "purchasable_id",   null: false
    t.string   "purchasable_type", null: false
    t.integer  "min_purchasable"
    t.integer  "max_purchasable"
    t.integer  "initial_amount"
    t.integer  "step"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  create_table "orders", force: :cascade do |t|
    t.integer  "customer_id",  null: false, index: {name: "fk__orders_customer_id"}, foreign_key: {references: "customers", name: "fk_orders_customer_id", on_update: :no_action, on_delete: :no_action}
    t.string   "number",       null: false, index: {name: "index_orders_on_number", unique: true}
    t.string   "aasm_state",   null: false
    t.datetime "completed_at"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  create_table "order_items", force: :cascade do |t|
    t.integer  "order_id",          null: false, index: {name: "fk__order_items_order_id"}, foreign_key: {references: "orders", name: "fk_order_items_order_id", on_update: :no_action, on_delete: :no_action}
    t.integer  "online_product_id", null: false, index: {name: "fk__order_items_online_product_id"}, foreign_key: {references: "online_products", name: "fk_order_items_online_product_id", on_update: :no_action, on_delete: :no_action}
    t.integer  "amount"
    t.decimal  "total",             precision: 8, scale: 2, null: false
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  create_table "payments", force: :cascade do |t|
    t.integer  "order_id",           null: false, index: {name: "fk__payments_order_id"}, foreign_key: {references: "orders", name: "fk_payments_order_id", on_update: :no_action, on_delete: :no_action}
    t.decimal  "amount",             precision: 8, scale: 2, null: false
    t.string   "terminal"
    t.string   "transaction_type"
    t.string   "card_country"
    t.string   "response_code"
    t.string   "authorization_code"
    t.string   "currency"
    t.string   "merchant_code"
    t.boolean  "success"
    t.string   "payment_type"
    t.datetime "paid_at"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

end
