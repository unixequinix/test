class CreditsPresenter < BasePresenter
  def can_render?
    @profile.active_credentials? && @profile.completed_claims.empty?
  end

  def path
    @event.finished? ? "events/events/credits_after_event" : "events/events/credits"
  end

  def customer_total_credits
    # TODO: Check this
    number_with_precision(@profile.total_credits, precision: 2)
  end

  def event_started?
    @event.started?
  end

  def refundable_credits
    number_with_precision(@profile.total_refundable, precision: 2)
  end

  def refundable_money
    number_with_precision(@profile.refundable_money_amount, precision: 2)
  end

  def token_symbol
    @event.token_symbol
  end

  def currency
    @event.currency
  end

  def valid_balance?
    BalanceCalculator.new(@profile).valid_balance?
  end

  def call_to_action
    if event_started?
      I18n.t("dashboard.credits.call_to_action_started")
    elsif @ticket_assignments.any?
      I18n.t("dashboard.credits.call_to_action")
    else
      I18n.t("dashboard.credits.call_to_action_no_admission_html").html_safe
    end
  end
end
