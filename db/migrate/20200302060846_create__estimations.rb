class CreateEstimations < ActiveRecord::Migration[5.2]
  def change
    create_table :estimations do |t|
      t.integer :cost_estimation
      t.integer :task_estimation
      t.references :cost
      t.timestamps null: false
    end
  end
end
