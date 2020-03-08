class CreateTasks < ActiveRecord::Migration[5.2]
  def change
    create_table :tasks do |t|
      t.string :name
      t.text :task_comment
      t.date :due_date
      t.boolean :completed
      t.string :hashtag
      t.integer :relative_evaluation
      t.references :user
      t.timestamps null: false
    end
  end
end
