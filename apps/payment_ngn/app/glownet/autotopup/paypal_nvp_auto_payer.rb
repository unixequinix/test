class Autotopup::PaypalNvpAutoPayer
  def self.start(tag_uid, order_id, event) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    profile = event.gtags.find_by_tag_uid(tag_uid)&.assigned_profile
    return { errors: "Customer not found" } if profile.nil?
    credit = event.credits.standard

    p_gateway = profile.payment_gateway_customers.find_by(gateway_type: "paypal_nvp")
    return { errors: "No agreement accepted" } if p_gateway.nil?

    order = Order.new(profile: profile, number: order_id)
    amount = p_gateway.autotopup_amount
    value = credit.value
    order.order_items << OrderItem.new(catalog_item_id: credit.catalog_item.id,
                                       amount: amount,
                                       total: amount * value)
    order.save

    data = { event_id: event.id, order_id: order.id }
    charge = Payments::PaypalNvpPayer.new.start(data,
                                                CustomerOrderCreator.new,
                                                CustomerCreditAutotopupOrderCreator.new)

    return { errors: charge.errors.to_json } unless charge["ACK"] == "Success"
    { profile: profile }
  end
end
