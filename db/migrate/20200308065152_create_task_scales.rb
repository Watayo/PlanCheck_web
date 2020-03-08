class CreateTaskScales < ActiveRecord::Migration[5.2]
  def change
    create_table :task_scales do |t|
      t.references :task
      #重みつけ関数とか用意したいな
    end
  end
end