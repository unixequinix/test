class AddDescriptionToTicket < ActiveRecord::Migration
  def change
    add_column :tickets, :description, :string
  end
end
