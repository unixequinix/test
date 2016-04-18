class CustomerCreditTicketCreator < CustomerCreditCreator
  def assign(ticket)
    loop_credits(ticket, CustomerCredit::TICKET_ASSIGNMENT)
  end

  def unassign(ticket)
    loop_credits(ticket, CustomerCredit::TICKET_UNASSIGNMENT, -1)
  end

  private

  def loop_credits(ticket, origin, sign = 1)
    ticket.credits.each do |credit|
      params = { amount: (credit.total_amount * sign), origin: origin, credit_value: credit.value }
      create_credit(ticket.assigned_customer_event_profile, params)
    end
  end
end
