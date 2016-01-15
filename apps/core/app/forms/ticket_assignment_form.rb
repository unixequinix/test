class TicketAssignmentForm
  include ActiveModel::Model
  include Virtus.model

  attribute :number, String

  validates_presence_of :number

  def save(ticket_fetcher, current_customer_event_profile, current_event)
    ticket = ticket_fetcher.find_by(number: number.strip)
    if !ticket.nil?
      if valid?
        persist!(ticket, current_customer_event_profile)
        true
      else
        errors.add(:ticket_assignment, full_messages.join('. '))
        false
      end
    else
      errors.add(:ticket_assignment,
                 I18n.t('alerts.admissions',
                        companies: TicketType.companies(current_event).join(', '))
                )
      false
    end
  end

  private

  def persist!(ticket, current_customer_event_profile)
    current_customer_event_profile.save
    current_customer_event_profile.credential_assignments.create(credentiable: ticket)
    return unless ticket.ticket_type.credit.present?
    CreditLog.create(customer_event_profile: current_customer_event_profile,
                     transaction_type: CreditLog::TICKET_ASSIGNMENT,
                     amount: ticket.ticket_type.credit)
  end
end
