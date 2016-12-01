# == Schema Information
#
# Table name: gtags
#
#  activation_counter       :integer          default(1)
#  active                   :boolean          default(TRUE)
#  banned                   :boolean          default(FALSE)
#  credits                  :decimal(8, 2)
#  final_balance            :decimal(8, 2)
#  final_refundable_balance :decimal(8, 2)
#  format                   :string           default("wristband")
#  loyalty                  :boolean          default(FALSE)
#  refundable_credits       :decimal(8, 2)
#
# Indexes
#
#  index_gtags_on_customer_id  (customer_id)
#  index_gtags_on_event_id     (event_id)
#
# Foreign Keys
#
#  fk_rails_084fd46c5e  (event_id => events.id)
#  fk_rails_70b4405c01  (customer_id => customers.id)
#

require "spec_helper"

RSpec.describe Gtag, type: :model do
  subject { create(:gtag) }

  it "has a valid factory" do
    expect(subject).to be_valid
  end

  describe ".upcase_gtag!" do
    it "upcases the tag_uid" do
      subject.tag_uid = "aaa"
      subject.valid?
      expect(subject.tag_uid).to eq("AAA")
    end
  end

  it "responds to the method card?" do
    expect(subject).to respond_to(:card?)
  end

  it "responds to the method wristband?" do
    expect(subject).to respond_to(:wristband?)
  end
end
