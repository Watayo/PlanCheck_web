class CreateTaskHashtags < ActiveRecord::Migration[5.2]
  def change
    create_table :hashtags do |t|
      t.references :task, foreign_key: true
      t.references :tag, foreign_key: true
      t.index [:task_id, :tag_id], unique: true
    end
  end
end
