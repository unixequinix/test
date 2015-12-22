class GtagRegistrationsPresenter < BasePresenter
  def can_render?
    @event.refunds?
  end

  def path
    @gtag_assignment.present? ? "gtag_registrations" : "new_gtag_registrations"
  end

  def gtag_registrations_enabled?
    @event.gtag_assignment?
  end

  def customer_has_refund?
    @refund.present?
  end
end
