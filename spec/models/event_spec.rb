# == Schema Information
#
# Table name: events
#
#  aasm_state                      :string
#  address_mandatory               :boolean
#  agreed_event_condition          :boolean
#  background_content_type         :string
#  background_file_name            :string
#  background_file_size            :integer
#  background_type                 :string           default("fixed")
#  birthdate_mandatory             :boolean
#  cards_can_refund                :boolean          default(TRUE)
#  city_mandatory                  :boolean
#  company_name                    :string
#  country_mandatory               :boolean
#  currency                        :string           default("USD"), not null
#  days_to_keep_backup             :integer          default(5)
#  device_basic_db_content_type    :string
#  device_basic_db_file_name       :string
#  device_basic_db_file_size       :integer
#  device_full_db_content_type     :string
#  device_full_db_file_name        :string
#  device_full_db_file_size        :integer
#  end_date                        :datetime
#  eventbrite_client_key           :string
#  eventbrite_client_secret        :string
#  eventbrite_event                :string
#  eventbrite_token                :string
#  fast_removal_password           :string           default("123456")
#  gender_mandatory                :boolean
#  gtag_assignation                :boolean          default(FALSE)
#  gtag_deposit                    :integer          default(0)
#  gtag_format                     :string           default("standard")
#  gtag_type                       :string           default("ultralight_c")
#  iban_enabled                    :boolean          default(TRUE)
#  logo_content_type               :string
#  logo_file_name                  :string
#  logo_file_size                  :integer
#  maximum_gtag_balance            :integer          default(300)
#  mifare_classic_private_key_a    :string
#  mifare_classic_private_key_b    :string
#  mifare_classic_public_key       :string
#  name                            :string           not null
#  official_address                :string
#  official_name                   :string
#  phone_mandatory                 :boolean
#  pos_update_online_orders        :boolean          default(FALSE)
#  postcode_mandatory              :boolean
#  private_zone_password           :string           default("123456")
#  receive_communications          :boolean
#  receive_communications_two      :boolean
#  registration_num                :string
#  slug                            :string           not null
#  start_date                      :datetime
#  style                           :text
#  support_email                   :string           default("support@glownet.com"), not null
#  sync_time_basic_download        :integer          default(5)
#  sync_time_customers             :integer          default(10)
#  sync_time_event_parameters      :integer          default(1)
#  sync_time_gtags                 :integer          default(10)
#  sync_time_server_date           :integer          default(1)
#  sync_time_tickets               :integer          default(5)
#  ticket_assignation              :boolean          default(FALSE)
#  timezone                        :string           default("UTC")
#  token                           :string
#  token_symbol                    :string           default("t")
#  topup_initialize_gtag           :boolean          default(TRUE)
#  touchpoint_update_online_orders :boolean          default(FALSE)
#  transaction_buffer              :integer          default(100)
#  ultralight_c_private_key        :string
#  ultralight_ev1_private_key      :string
#  wristbands_can_refund           :boolean          default(TRUE)
#
# Indexes
#
#  index_events_on_slug  (slug) UNIQUE
#

require "spec_helper"

RSpec.describe Event, type: :model do
  subject { build(:event) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:support_email) }

  describe ".eventbrite?" do
    it "returns true if the event has eventbrite_token and eventbrite_event" do
      expect(subject).not_to be_eventbrite
      subject.eventbrite_token = "test"
      expect(subject).not_to be_eventbrite
      subject.eventbrite_event = "test"
      expect(subject).to be_eventbrite
    end
  end

  describe ".credit_price" do
    it "returns the event credit value" do
      subject.save
      subject.create_credit!(value: 1, step: 5, min_purchasable: 0, max_purchasable: 300, initial_amount: 0, name: "CR")
      expect(subject.credit_price).to eq(subject.credit.value)
    end
  end

  describe ".active?" do
    it "returns true if the event is launched, started or finished" do
      subject.aasm_state = "closed"
      expect(subject).not_to be_active
      subject.aasm_state = "created"
      expect(subject).not_to be_active

      subject.aasm_state = "launched"
      expect(subject).to be_active
      subject.aasm_state = "started"
      expect(subject).to be_active
      subject.aasm_state = "finished"
      expect(subject).to be_active
    end
  end

  describe ".refunds" do
    it "returns the event refunds" do
      subject.save
      refund = create(:refund, customer: create(:customer, event: subject))
      expect(subject.refunds).to eq([refund])
    end
  end

  describe ".orders" do
    it "returns the event orders" do
      subject.save
      order = create(:order, customer: create(:customer, event: subject))
      expect(subject.orders).to eq([order])
    end
  end
end
