class Payments::BraintreePayer
  attr_reader :action_after_payment

  def initialize
    @action_after_payment = ""
  end

  def start(params)
    charge_object = charge(params)
    if charge_object.success?
      notify_payment(params, charge_object)
      @action_after_payment = "redirect_to(success_event_order_payments_path)"
    else
      @action_after_payment = "redirect_to(error_event_order_payments_path)"
    end
  end

  def charge(params)
    begin
      charge = Braintree::Transaction.sale(sale_options(params))
    rescue Braintree::ErrorResult
      # The card has been declined
      charge = nil
    end
    charge
  end

  def sale_options(params)
    token = params[:payment_method_nonce]
    order = Order.find(params[:order_id])
    customer_event_profile = order.customer_event_profile
    customer = customer_event_profile.customer
    amount = order.total_stripe_formated
    sale_options = {
      amount: amount,
      payment_method_nonce: token
    }
    unless customer_event_profile.gateway_customer(Event::BRAINTREE)
      sale_options[:customer] = {
        first_name: customer.name,
        last_name: customer.surname,
        email: customer.email
      }
      sale_options[:options] = {
        store_in_vault: true
      }
    end
    sale_options
  end

  def notify_payment(params, charge)
    transaction = charge.transaction
    asdfasdf
    return unless transaction.status == "authorized"
    order = Order.find(params[:order_id])
    customer_event_profile = order.customer_event_profile
    CreditLog.create(customer_event_profile_id: order.customer_event_profile.id, transaction_type: CreditLog::CREDITS_PURCHASE, amount: order.credits_total)
    binding.pry
    payment = Payment.new(
      order: order,
      amount: (transaction.amount.to_f / 100), # last two digits are decimals,
      merchant_code: transaction.id,
      currency: order.customer_event_profile.event.currency,
      paid_at: Time.at(transaction.created_at),
      response_code: transaction,
      success: true,
      payment_type: 'braintree'
    )
    payment.save!
    order.complete!
    customer_event_profile.gateway_customer(Event::BRAINTREE).update(token: transaction.customer_details.id)
    customer_event_profile.save
    send_mail_for(order, Event.friendly.find(params[:event_id]))
  end

  private

  def send_mail_for(order, event)
    OrderMailer.completed_email(order, event).deliver_later
  end

  def get_event_parameter_value(event, name)
    EventParameter.find_by(event_id: event.id, parameter: Parameter.where(category: "payment", group: "braintree", name: name)).value
  end
end
