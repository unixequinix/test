class Jobs::Credit::BalanceUpdater < Jobs::Base
  SUBSCRIPTIONS = %w( sale topup refund fee sale_refund )

  def perform(atts)
    credit_atts = Jobs::Base.extract_attributes(CustomerCredit, atts)
    # TODO: there is a before filter in CustomerCredit that overrides this
    CustomerCredit.create!(credit_atts.merge(created_in_origin_at: atts[:device_created_at]))
  end
end
