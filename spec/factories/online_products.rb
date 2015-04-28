# == Schema Information
#
# Table name: online_products
#
#  id          :integer          not null, primary key
#  name        :string
#  description :text
#  price       :decimal(8, 2)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

FactoryGirl.define do
  factory :online_product do
    name { Faker::Lorem.word }
    description { Faker::Lorem.sentence }
    price "9.99"
  end

end
