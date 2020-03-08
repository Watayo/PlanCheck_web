class CreateEstimations < ActiveRecord::Migration[5.2]
  def change
    create_table :estimations do |t|
      t.integer :estimation
      t.text :estimation_comment
      t.references :task
      t.references :task_scale
      t.references :task_period
      t.references :task_manhour
      t.references :task_experience
      t.timestamps null: false
    end
  end
end
