class Jobs::Credential::Accreditator < Jobs::Base
  TYPES = %w( accreditation )

  def perform(transaction_id, atts = {})
    ActiveRecord::Base.transaction do
      t = CredentialTransaction.find(transaction_id)
      profile = t.customer_event_profile || t.create_customer_event_profile!(event: t.event)
      gtag = t.event.gtags.find_by(tag_uid: t.customer_tag_uid)
      return if gtag.assigned_gtag_credential
      gtag.create_assigned_gtag_credential!(customer_event_profile: profile)
    end

    Jobs::Credential::OrderCreator.perform_later(atts)
  end
end
