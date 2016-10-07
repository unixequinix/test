class RefundNotification
  def notify(event)
    notify_customers_to(event) if event.finished?
  end

  private

  def notify_customers_to(event)
    Profile.with_gtag(event).all? { |profile| send_mail_to(profile, event) }
  end

  def send_mail_to(profile, event)
    ClaimMailer.notification_email(profile, event).deliver_later
  end
end