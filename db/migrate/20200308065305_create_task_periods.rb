class CreateTaskPeriods < ActiveRecord::Migration[5.2]
  def change
    create_table :task_periods do |t|
      t.references :task
    end
  end
end
