# == Schema Information
#
# Table name: companies
#
#  access_token :string
#  name         :string           not null
#

FactoryGirl.define do
  factory :company do
    sequence(:name) { |n| "Company #{n}" }

    trait :with_company_event_agreement do
      after(:build) do |company|
        company.company_event_agreements << build(:company_event_agreement, company: company)
      end
    end
  end
end
