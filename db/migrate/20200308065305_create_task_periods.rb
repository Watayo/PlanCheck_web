class CreateTaskPeriods < ActiveRecord::Migration[5.2]
  def change
    create_table :task_periods do |t|
      t.integer :period_value
    end
  end
end
