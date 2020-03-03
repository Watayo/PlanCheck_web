class CreateTasks < ActiveRecord::Migration[5.2]
  def change
    create_table :tasks do |t|
      t.string :name
      t.text :task_comment
      t.datetime :due_time
      t.boolean :completed
      t.boolean :star
      t.references :user
      t.timestamps null: false
    end
  end
end
