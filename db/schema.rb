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

ActiveRecord::Schema[8.0].define(version: 2025_10_25_004954) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "endorsements", force: :cascade do |t|
    t.bigint "policy_id", null: false
    t.date "issue_date"
    t.string "endorsement_type"
    t.decimal "insured_amount", precision: 15, scale: 2
    t.date "start_date"
    t.date "end_date"
    t.integer "cancelled_endorsement_id"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cancelled_endorsement_id"], name: "index_endorsements_on_cancelled_endorsement_id"
    t.index ["endorsement_type"], name: "index_endorsements_on_endorsement_type"
    t.index ["policy_id"], name: "index_endorsements_on_policy_id"
    t.index ["status"], name: "index_endorsements_on_status"
  end

  create_table "policies", force: :cascade do |t|
    t.string "number"
    t.date "issue_date"
    t.date "start_date"
    t.date "end_date"
    t.decimal "insured_amount", precision: 15, scale: 2
    t.decimal "maximum_coverage", precision: 15, scale: 2
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "original_start_date"
    t.date "original_end_date"
    t.index ["number"], name: "index_policies_on_number", unique: true
  end

  add_foreign_key "endorsements", "policies"
end
