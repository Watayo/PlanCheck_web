class CreateTaskExperiences < ActiveRecord::Migration[5.2]
  def change
    create_table :task_experiences do |t|
      t.integer :experience_value
    end
  end
end
