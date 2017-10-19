module TransactionsHelper
  def create_gtag(tag_uid, event_id)
    # ticket_activation transactions dont have tag_uid
    return unless tag_uid

    Gtag.find_or_create_by(tag_uid: tag_uid, event_id: event_id)
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  def apply_customers(event, customer_id, credential)
    claimed = Customer.claim(event, customer_id, credential.customer_id)
    return customer_id if claimed.present?

    credential.update!(customer_id: customer_id) if customer_id.present?
    credential.update!(customer_id: Customer.create!(event_id: event.id, anonymous: true).id) if credential.customer_id.blank?
    credential.customer_id
  end
end