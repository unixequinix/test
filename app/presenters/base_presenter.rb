class BasePresenter
  include ActionView::Helpers::NumberHelper
  attr_accessor :context, :customer, :gtag, :refund, :event, :tickets

  def initialize(dashboard, context)
    @context = context
    @customer = dashboard.customer
    @event = dashboard.event
    @tickets = dashboard.tickets
    @gtag = dashboard.gtag
  end

  def event_url
    @event.url
  end

  def credential_present?
    @tickets.any? || @gtags.any?
  end

  delegate :tag_uid, to: :gtag, prefix: true

  private

  def formatted_date
    Time.zone.now.strftime("%Y-%m-%d")
  end
end
