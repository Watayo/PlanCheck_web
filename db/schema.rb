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

ActiveRecord::Schema.define(version: 2020_03_08_065534) do

  create_table "estimations", force: :cascade do |t|
    t.integer "estimation"
    t.text "estimation_comment"
    t.integer "task_id"
    t.integer "task_scale_id"
    t.integer "task_period_id"
    t.integer "task_manhour_id"
    t.integer "task_experience_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["task_experience_id"], name: "index_estimations_on_task_experience_id"
    t.index ["task_id"], name: "index_estimations_on_task_id"
    t.index ["task_manhour_id"], name: "index_estimations_on_task_manhour_id"
    t.index ["task_period_id"], name: "index_estimations_on_task_period_id"
    t.index ["task_scale_id"], name: "index_estimations_on_task_scale_id"
  end

  create_table "feedbacks", force: :cascade do |t|
    t.integer "fact"
    t.text "feedback_comment"
    t.integer "task_id"
    t.integer "task_scale_id"
    t.integer "task_period_id"
    t.integer "task_manhour_id"
    t.integer "task_experience_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["task_experience_id"], name: "index_feedbacks_on_task_experience_id"
    t.index ["task_id"], name: "index_feedbacks_on_task_id"
    t.index ["task_manhour_id"], name: "index_feedbacks_on_task_manhour_id"
    t.index ["task_period_id"], name: "index_feedbacks_on_task_period_id"
    t.index ["task_scale_id"], name: "index_feedbacks_on_task_scale_id"
  end

  create_table "task_experiences", force: :cascade do |t|
    t.integer "experience_value"
  end

  create_table "task_manhours", force: :cascade do |t|
    t.integer "manhour_value"
  end

  create_table "task_periods", force: :cascade do |t|
    t.integer "period_value"
  end

  create_table "task_scales", force: :cascade do |t|
    t.integer "scale_value"
  end

  create_table "tasks", force: :cascade do |t|
    t.string "name"
    t.text "task_comment"
    t.date "due_date"
    t.boolean "completed"
    t.string "hashtag"
    t.integer "relative_evaluation"
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
