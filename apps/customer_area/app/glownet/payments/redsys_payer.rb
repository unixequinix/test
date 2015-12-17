class Payments::RedsysPayer

  def start(params)
    notify_payment(params)
  end

  def notify_payment(params)
    event = Event.friendly.find(params[:event_id])
    merchant_code = EventParameter.find_by(event_id: event.id, parameter_id: Parameter.find_by(category: "payment", group: "redsys", name: "code")).value
     if params[:Ds_Order] and params[:Ds_MerchantCode] == merchant_code
      response = params[:Ds_Response]
      success = response =~ /00[0-9][0-9]|0900/
      amount = params[:Ds_Amount].to_f / 100 # last two digits are decimals
      if success
        order = Order.find_by(number: params[:Ds_Order])
        credit_log = CreditLog.create(customer_event_profile_id: order.customer_event_profile.id, transaction_type: CreditLog::CREDITS_PURCHASE, amount: order.credits_total)
        payment = Payment.new(
          transaction_type: params[:Ds_TransactionType],
          card_country: params[:Ds_Card_Country],
          paid_at: "#{params[:Ds_Date]}, #{params[:Ds_Hour]}",
          order: order,
          response_code: response,
          authorization_code: params[:Ds_AuthorisationCode],
          currency: params[:Ds_Currency],
          merchant_code: params[:Ds_MerchantCode],
          amount: amount,
          terminal: params[:Ds_Terminal],
          success: true)
        payment.save!
        order.complete!
        send_mail_for(order, event)
      end
    end
  end

  def action_after_payment
    # this method will be evaluated in the controller
    "render nothing: true"
  end

  private

  def send_mail_for(order, event)
    OrderMailer.completed_email(order, event).deliver_later
  end
end