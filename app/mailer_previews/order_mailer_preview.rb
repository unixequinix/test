class OrderMailerPreview < ActionMailer::Preview
  def completed_email
    profile = Profile.first || FactoryGirl.create(:profile, event: Event.first)
    order = FactoryGirl.create(:order, profile: profile)
    order.update!(completed_at: Time.zone.now)
    order.order_items.create(amount: 10, total: 20, catalog_item: CatalogItem.first)
    OrderMailer.completed_email(order, Event.first)
  end
end