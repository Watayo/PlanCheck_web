class CreateFeedbacks < ActiveRecord::Migration[5.2]
  def change
    create_table :feedbacks do |t|
      t.integer :fact, default: 0
      t.text :feedback_comment
      t.references :task_scale
      t.references :task_period
      t.references :task_manhour
      t.references :task_experience
      t.timestamps null: false
    end
  end
end
