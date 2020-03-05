class CreateFeedbacks < ActiveRecord::Migration[5.2]
  def change
    create_table :feedbacks do |t|
      t.integer :cost_fact
      t.integer :task_fact
      t.text :feedback_comment
      t.references :task
      t.references :cost
    end
  end
end
