class CreateStationGroups < ActiveRecord::Migration
  def change
    create_table :station_groups do |t|
      t.string :name, index: true, null: false
      t.timestamps null: false
    end
  end
end
