class RemovePurchasersFromPalco4 < ActiveRecord::Migration[5.1]
  def change
    Ticket.where(ticket_type: TicketType.where(company: "Palco4")).update_all(purchaser_first_name: nil, purchaser_last_name: nil, purchaser_email: nil)
  end
end
