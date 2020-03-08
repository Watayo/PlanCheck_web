class CreateTaskExperiences < ActiveRecord::Migration[5.2]
  def change
    create_table :task_experiences do |t|
      t.references :task
    end
  end
end
