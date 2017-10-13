module PaymentGatewaysHelper
  def store_redirection(event, type, options = {})
    return send("new_event_#{type}_path", event) unless event.payment_gateways.vouchup.any?

    return path unless event.payment_gateways.topup.pluck(:name).include?('vouchup')

    params = { path: "/register/#{event.slug}/glownet/#{current_customer.id}" }
    params = { path: "/refund/#{event.slug}/customer-details", query: { email: current_customer.email, gtag: options[:gtag_uid] }.to_param } if type == :refund # rubocop:disable Metrics/LineLength

    url = { host: YAML.load_file(Rails.root.join('config', 'glownet', 'payment_gateways.yml'))["vouchup"]["host"][Rails.env] }.merge(params)

    "https://#{URI::HTTP.build(url)}"
  end
end
