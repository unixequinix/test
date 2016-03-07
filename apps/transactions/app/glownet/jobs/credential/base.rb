class Jobs::Credential::Base < Jobs::Base
  def assign_profile(transaction, atts)
    transaction.customer_event_profile ||
      transaction.create_customer_event_profile!(event_id: atts[:event_id])
  end

  def assign_gtag(transaction, atts)
    gtags = transaction.event.gtags
    atts = { tag_uid: atts[:customer_tag_uid], company_ticket_type: atts[:company_ticket_type] }
    gtags.find_by(atts) || gtags.create!(atts)
  end

  def assign_gtag_credential(gtag, profile)
    return if gtag.assigned_gtag_credential
    gtag.create_assigned_gtag_credential!(customer_event_profile: profile)
  end

  def assign_ticket(transaction, atts)
    transaction.ticket ||
      transaction.create_ticket!(event_id: atts[:event_id],
                                 code: atts[:ticket_code],
                                 company_ticket_type_id: atts[:company_ticket_type])
  end

  def assign_ticket_credential(ticket, profile)
    return if ticket.assigned_ticket_credential
    ticket.create_assigned_ticket_credential!(customer_event_profile: profile)
  end

  def mark_redeemed(obj)
    obj.update!(credential_redeemed: true)
  end
end
