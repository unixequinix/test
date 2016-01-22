# == Schema Information
#
# Table name: preevent_products
#
#  id              :integer          not null, primary key
#  event_id        :integer          not null
#  name            :string
#  online          :boolean          default(FALSE), not null
#  initial_amount  :integer
#  step            :integer
#  max_purchasable :integer
#  min_purchasable :integer
#  price           :decimal(, )
#  deleted_at      :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

FactoryGirl.define do
  factory :preevent_product do
    name { Faker::Number.between(1, 20) }
    online { [true, false].sample }
    event
  end
end
