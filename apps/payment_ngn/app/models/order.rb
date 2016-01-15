# == Schema Information
#
# Table name: orders
#
#  id                        :integer          not null, primary key
#  number                    :string           not null
#  aasm_state                :string           not null
#  completed_at              :datetime
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  customer_event_profile_id :integer
#

class Order < ActiveRecord::Base
  default_scope { order(created_at: :desc) }

  # Associations
  belongs_to :customer_event_profile
  has_many :order_items
  has_many :payments
  has_many :order_items
  has_many :preevent_products, through: :order_items, class_name: 'PreeventProduct'

  # Validations
  validates :customer_event_profile, :order_items, :number, :aasm_state, presence: true

  # State machine
  include AASM

  aasm do
    state :started, initial: true
    state :in_progress
    state :completed, enter: :complete_order

    event :start_payment do
      transitions from: [:started, :in_progress], to: :in_progress
    end

    event :complete do
      transitions from: :in_progress, to: :completed
    end
  end

  def total
    order_items.sum(:total)
  end

  def total_stripe_formated
    total_formated = sprintf "%.2f", total
    total_formated.gsub(".", "")
  end

  def credits_total
    order_items.joins(:online_product).where(online_products: { purchasable_type: "Credit", event_id: customer_event_profile.event.id }).sum(:amount)
  end

  def generate_order_number!
    time_hex = Time.now.strftime("%H%M%L").to_i.to_s(16)
    day = Date.today.strftime("%y%m%d")
    self.number = "#{day}#{time_hex}"
    save
  end

  def expired?
    Time.now > created_at + 15.minutes
  end

  private

  def complete_order
    update(completed_at: Time.now)
  end
end
