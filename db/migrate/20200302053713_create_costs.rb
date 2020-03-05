class CreateCosts < ActiveRecord::Migration[5.2]
  def change
    create_table :costs do |t|
      t.string :name
      t.string :parameter_name
      t.text :def_explain
      t.float :statistic_info
      t.references :user
      t.references :task
      t.references :estimation
    end
  end
end
