class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.belongs_to :customer, null: false
      t.belongs_to :online_product, null: false
      t.string :number, null: false
      t.decimal :amount, precision: 8, scale: 2, null: false
      t.string :aasm_state, null: false
      t.datetime :completed_at

      t.timestamps null: false
    end
  end
end
