class RenameOrdersAndRefundsAmount < ActiveRecord::Migration[5.1]
  def change
    remove_column :order_items, :total, :decimal
  end
end
