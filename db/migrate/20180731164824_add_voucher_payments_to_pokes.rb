class AddVoucherPaymentsToPokes < ActiveRecord::Migration[5.1]
  def change
    add_column :pokes, :voucher_amount, :integer, default: 0
  end
end
