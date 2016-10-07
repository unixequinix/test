class StripePaymentSettingsForm < BaseSettingsForm
  attribute :email, String
  attribute :currency, String
  attribute :country, String
  attribute :bank_account, String
  attribute :legal_first_name, String
  attribute :legal_last_name, String
  attribute :legal_dob, DateTime
  attribute :legal_type, String

  # Aditional Owner
  attribute :additional_owner_first_name, String
  attribute :additional_owner_last_name, String
  attribute :additional_owner_dob, DateTime
  attribute :additional_owner_address_city, String
  attribute :additional_owner_address_line1, String
  attribute :additional_owner_address_postal_code, String

  attribute :business_name, String
  attribute :business_tax_id, String
  attribute :city, String
  attribute :line1, String
  attribute :postal_code, String
  attribute :tos_acceptance_date, String
  attribute :tos_acceptance_ip, String
  attribute :event_id, Integer
  attribute :application_fee, Integer
  attribute :stripe_account_id, String
  attribute :account_secret_key, String
  attribute :account_publishable_key, String
  attribute :document, String
  attribute :additional_owner_document, String

  validates_presence_of :email
  validates_presence_of :currency
  validates_presence_of :country
  validates_presence_of :application_fee

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def save(params, request)
    return unless valid?

    manager = AccountManager::Stripe.new
    p = params[:stripe_payment_settings_form]

    begin
      # rubocop:disable Metrics/LineLength
      self.document = manager.upload_document(p[:document], p[:stripe_account_id], p[:account_secret_key]) if p[:document]
      self.additional_owner_document = manager.upload_document(p[:additional_owner_document], p[:stripe_account_id], p[:account_secret_key]) if p[:additional_owner_document]
      manager.update_parameters(attributes, request)
      manager.update_bank_account(p)
    rescue Stripe::CardError => e
      err = e.json_body[:error]
      errors.add(:card, ": #{err[:message]}") && return
    rescue Stripe::InvalidRequestError => e
      err = e.json_body[:error]
      errors.add(:request, ": #{err[:message]}") && return
    rescue Stripe::AuthenticationError => e
      err = e.json_body[:error]
      errors.add(:authentication, ": #{err[:message]}") && return
    rescue Stripe::APIConnectionError => e
      err = e.json_body[:error]
      errors.add(:api_connection, ": #{err[:message]}") && return
    rescue Stripe::StripeError => e
      err = e.json_body[:error]
      errors.add(:stripe, ": #{err[:message]}") && return
    end

    persist!
  end

  def main_parameters
    attributes.keys.reject { |value| value == :event_id || value == :document || value == :additional_owner_document }
  end

  private

  def persist!
    Parameter.where(category: "payment", group: "stripe").each do |parameter|
      next unless attributes[parameter.name.to_sym]
      ep = EventParameter.find_or_create_by(event_id: event_id, parameter_id: parameter.id)
      value = attributes[parameter.name.to_sym]
      ep.update(value: value)
    end
  end
end