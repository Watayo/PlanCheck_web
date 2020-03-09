class CreateTasks < ActiveRecord::Migration[5.2]
  def change
    create_table :tasks do |t|
      t.string :name
      t.text :task_comment
      t.date :due_date
      t.boolean :completed
      t.boolean :feedback_done
      t.integer :final_eval
      t.string :hashtag
      t.references :user
      t.timestamps null: false
    end
  end
end
