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

ActiveRecord::Schema.define(version: 2020_03_02_060846) do

  create_table "costs", force: :cascade do |t|
    t.string "name"
    t.string "parameter_name"
    t.text "def_explain"
    t.float "statistic_info"
    t.integer "user_id"
    t.integer "task_id"
    t.index ["task_id"], name: "index_costs_on_task_id"
    t.index ["user_id"], name: "index_costs_on_user_id"
  end

  create_table "estimations", force: :cascade do |t|
    t.integer "cost_estimation"
    t.integer "task_estimation"
    t.integer "task_id"
    t.integer "cost_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cost_id"], name: "index_estimations_on_cost_id"
    t.index ["task_id"], name: "index_estimations_on_task_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.string "name"
    t.text "task_comment"
    t.datetime "due_time"
    t.boolean "completed"
    t.boolean "star"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_tasks_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "img"
    t.string "sub"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
