FactoryBot.define do
  factory :money_transaction do
    event
    device
    station
    sequence(:action) { |n| "action #{n}" }
    sequence(:device_db_index)
    transaction_origin { "onsite" }
    device_created_at { Time.zone.now.to_s[0, 19] }
    device_created_at_fixed { Time.zone.now.to_s }
    customer_tag_uid { SecureRandom.hex(6).upcase }
    operator_tag_uid { SecureRandom.hex(6).upcase }
    sequence(:items_amount)
    sequence(:price)
    payment_gateway { "paypal" }
    payment_method { %w[bank_account epg].sample }
  end

  factory :operator_transaction do
    event
    device
    station
    sequence(:action) { |n| "action #{n}" }
    sequence(:device_db_index)
    transaction_origin { "onsite" }
    device_created_at { Time.zone.now.to_s[0, 19] }
    device_created_at_fixed { Time.zone.now.to_s }
    customer_tag_uid { SecureRandom.hex(6).upcase }
    operator_tag_uid { SecureRandom.hex(6).upcase }
  end

  factory :credit_transaction do
    event
    device
    station
    sequence(:action) { |n| "action #{n}" }
    sequence(:device_db_index)
    transaction_origin { "onsite" }
    device_created_at { Time.zone.now.to_s[0, 19] }
    device_created_at_fixed { Time.zone.now.to_s }
    customer_tag_uid { SecureRandom.hex(6).upcase }
    operator_tag_uid { SecureRandom.hex(6).upcase }
    sequence(:credits)
    sequence(:refundable_credits)
    sequence(:final_balance)
    sequence(:final_refundable_balance)

    trait :with_sales do
      after(:build) do |credit_transaction|
        rand(1..5).times do |_index|
          sale_item = create(:sale_item,
                             quantity: 1,
                             credit_transaction: credit_transaction,
                             product: create(:product, station: credit_transaction.station))

          credit_transaction.credits += (sale_item.standard_unit_price * sale_item.quantity)
          credit_transaction.save
        end
        other_amount = create(:sale_item, credit_transaction: credit_transaction, product: nil, quantity: 1)
        credit_transaction.credits += (other_amount.standard_unit_price * other_amount.quantity)
        credit_transaction.save
      end
    end

    trait :with_sale_refunds do
      after(:build) do |credit_transaction|
        rand(1..5).times do |_index|
          sale_item = create(:sale_item,
                             quantity: -1,
                             credit_transaction: credit_transaction,
                             product: create(:product, station: credit_transaction.station))

          credit_transaction.credits += (sale_item.standard_unit_price * sale_item.quantity)
          credit_transaction.save
        end
        other_amount = create(:sale_item, credit_transaction: credit_transaction, product: nil, quantity: -1)
        credit_transaction.credits += (other_amount.standard_unit_price * other_amount.quantity)
        credit_transaction.save
      end
    end
  end

  factory :credential_transaction do
    event
    device
    station
    sequence(:action) { |n| "action #{n}" }
    sequence(:device_db_index)
    transaction_origin { "onsite" }
    device_created_at { Time.zone.now.to_s[0, 19] }
    device_created_at_fixed { Time.zone.now.to_s }
    customer_tag_uid { SecureRandom.hex(6).upcase }
    operator_tag_uid { SecureRandom.hex(6).upcase }
  end

  factory :access_transaction do
    event
    device
    station
    sequence(:action) { |n| "action #{n}" }
    sequence(:device_db_index)
    transaction_origin { "onsite" }
    device_created_at { Time.zone.now.to_s[0, 19] }
    device_created_at_fixed { Time.zone.now.to_s }
    customer_tag_uid { SecureRandom.hex(6).upcase }
    operator_tag_uid { SecureRandom.hex(6).upcase }
    direction { 1 }
  end

  factory :order_transaction do
    event
    device
    station
    order
    sequence(:action) { |n| "action #{n}" }
    sequence(:device_db_index)
    transaction_origin { "onsite" }
    device_created_at { Time.zone.now.to_s[0, 19] }
    device_created_at_fixed { Time.zone.now.to_s }
    customer_tag_uid { SecureRandom.hex(6).upcase }
    operator_tag_uid { SecureRandom.hex(6).upcase }
  end

  factory :user_engagement_transaction do
    event
    device
    station
    order
    action { "exhibitor_note" }
    sequence(:device_db_index)
    message { "i love Glownet! " }
    sequence(:priority)
    transaction_origin { "onsite" }
    device_created_at { Time.zone.now.to_s[0, 19] }
    device_created_at_fixed { Time.zone.now.to_s }
    customer_tag_uid { SecureRandom.hex(6).upcase }
    operator_tag_uid { SecureRandom.hex(6).upcase }
  end

  factory :user_flag_transaction do
    event
    device
    station
    order
    action { "exhibitor_note" }
    sequence(:device_db_index)
    user_flag_active { true }
    user_flag { "yellow_flag" }
    transaction_origin { "onsite" }
    device_created_at { Time.zone.now.to_s[0, 19] }
    device_created_at_fixed { Time.zone.now.to_s }
    customer_tag_uid { SecureRandom.hex(6).upcase }
    operator_tag_uid { SecureRandom.hex(6).upcase }
  end

  factory :transaction do
    event
    device
    station
    sequence(:action) { |n| "action #{n}" }
    sequence(:device_db_index)
    transaction_origin { "onsite" }
    device_created_at { Time.zone.now.to_s[0, 19] }
    device_created_at_fixed { Time.zone.now.to_s }
    customer_tag_uid { SecureRandom.hex(6).upcase }
    operator_tag_uid { SecureRandom.hex(6).upcase }
  end
end
