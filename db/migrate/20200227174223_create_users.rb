class CreateUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :users do |t|
      t.string :name
      t.string :img
      t.string :sub
      t.timestamps null: false
    end
  end
end
