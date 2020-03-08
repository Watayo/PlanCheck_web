class CreateTaskManhours < ActiveRecord::Migration[5.2]
  def change
    create_table :task_manhours do |t|
      t.integer :manhour_value
    end
  end
end
