class CreateTreePlantations < ActiveRecord::Migration[5.2]
  def change
    create_table :tree_plantations do |t|
      t.string :project_name, null: false
      t.string :project_type
      t.string :plantation_uuid, null: false
      t.string :base_certificate_uuid, null: false
      t.decimal :lat, precision: 11, scale: 8, null: false
      t.decimal :long, precision: 11, scale: 8, null: false
      t.string :tree_specie, null: false
      t.string :producer_name, null: false
      t.integer :trees_quantity, null: false, default: 0

      t.timestamps
    end
  end
end
