class Payments::RedsysNotifier

  def initialize

  end

  def notify_payment(params)
    if params[:Ds_Order] and params[:Ds_MerchantCode] == Rails.application.secrets.merchant_code.to_s
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
        send_mail_for(order)
      end
    end
  end

  private

  def send_mail_for(order)
    OrderMailer.completed_email(order, current_event).deliver_later
  end
end