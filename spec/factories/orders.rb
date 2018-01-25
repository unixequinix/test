FactoryBot.define do
  factory :order do
    event
    gateway "paypal"
    customer { build(:customer, event: event) }

    trait :with_different_items do
      after :build do |order|
        order.order_items << build(:order_item, :with_access, order: order, amount: rand(1..100))
      end

      after :build do |order|
        order.order_items << build(:order_item, :with_credit, order: order, amount: rand(1..100))
      end
    end

    trait :with_credit do
      after :build do |order|
        order.order_items << build(:order_item, :with_credit, order: order, amount: rand(1..100))
      end
    end

    factory :order_with_items, traits: [:with_different_items]
  end
end
