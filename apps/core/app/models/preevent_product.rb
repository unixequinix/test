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

class PreeventProduct < ActiveRecord::Base
  acts_as_paranoid

  belongs_to :event
  has_many :company_ticket_types
  has_many :preevent_product_items
  has_many :preevent_items, through: :preevent_product_items, class_name: "PreeventItem"
  has_many :order_items
  has_many :orders, through: :order_items, class_name: "Order"

  accepts_nested_attributes_for :preevent_items
  accepts_nested_attributes_for :order_items
  accepts_nested_attributes_for :preevent_product_items, allow_destroy: true

  validates :event_id, :name, presence: true

  def rounded_price
    price.round == price ? price.floor : price
  end

  def self.online_preevent_products_sortered(current_event)
    preevent_products = where(event_id: current_event.id)
    @sortered_products_storage = Hash[keys_sortered.map { |key| [key, []] }]

    preevent_products.each do |preevent_product|
      next unless preevent_product.online
      category = is_a_pack?(preevent_product) ? "Pack" : nil
      add_product_to_storage(preevent_product, category)
    end
    @sortered_products_storage.values.flatten
  end

  private

  def self.keys_sortered
    %w(Credit Voucher CredentialType Pack)
  end

  def self.add_product_to_storage(preevent_product, new_category)
    category = new_category || get_product_category(preevent_product)
    @sortered_products_storage[category] << preevent_product
  end

  def self.get_product_category(preevent_product)
    preevent_product.preevent_items.first.purchasable_type
  end

  def self.is_a_pack?(preevent_product)
    preevent_product.preevent_items.count > 1
  end
end
