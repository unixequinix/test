class AddLastCardNumbersToPayments < ActiveRecord::Migration
  def change
    add_column :payments, :last4, :string
  end
end
