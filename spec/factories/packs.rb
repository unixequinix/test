# == Schema Information
#
# Table name: packs
#
#  id                  :integer          not null, primary key
#  catalog_items_count :integer          default(0), not null
#  deleted_at          :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

FactoryGirl.define do
  factory :pack do
    event
    name { "Random name #{rand(100)}" }
    initial_amount 0
    step { rand(5) }
    max_purchasable 1
    min_purchasable 0

    trait :with_credit do
      after :build do |pack|
        pack.pack_catalog_items.build(catalog_item: pack.event.credit, amount: 10)
      end
    end

    trait :with_access do
      after :build do |pack|
        pack.pack_catalog_items.build(catalog_item: create(:access), amount: 1)
      end
    end

    trait :with_user_flag do
      after :build do |pack|
        pack.pack_catalog_items.build(catalog_item: create(:user_flag), amount: 1)
      end
    end

    trait :empty do |_pack|
      after :create do |pack|
        pack.pack_catalog_items.clear
      end
    end

    factory :full_pack, traits: [:with_access, :with_credit, :with_user_flag]
    factory :credit_pack, traits: [:with_credit]
    factory :access_pack, traits: [:with_access]
    factory :empty_pack, traits: [:empty]
  end
end
