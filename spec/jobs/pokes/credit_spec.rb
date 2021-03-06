require "rails_helper"

RSpec.describe Pokes::Credit, type: :job do
  let(:worker) { Pokes::Credit }
  let(:event) { create(:event) }
  let(:gtag) { create(:gtag, event: event) }
  let(:customer) { create(:customer, event: event) }
  let(:payment) { { event.credit.id.to_s => { "credit_name" => event.credit.name, "credit_value" => event.credit.value, "amount" => 2.2 } } }
  let(:transaction) { create(:credit_transaction, action: "topup", event: event, payments: payment, gtag: gtag, customer: customer) }

  describe ".stat_creation" do
    let(:action) { "record_credit" }
    let(:name) { "topup" }

    include_examples "a poke"
  end

  it "calls recalculate_balance on the given gtag" do
    allow(CreditTransaction).to receive(:find).with(transaction.id).and_return(transaction)
    allow(transaction).to receive(:gtag).and_return(gtag)
    expect(gtag).to receive(:recalculate_balance).once
    worker.perform_now(transaction)
  end

  it "creates an alert when customer and operator tag_uids are the same" do
    transaction.update!(operator_tag_uid: gtag.tag_uid, customer_tag_uid: gtag.tag_uid)

    expect(Alert).to receive(:propagate).with(event, transaction, "has the same operator and customer UIDs", :medium).once
    worker.perform_now(transaction)
  end

  it "does not create an alert when customer and operator tag_uids are different" do
    transaction.update!(operator_tag_uid: "NOTTHESAME")

    expect(Alert).not_to receive(:propagate)
    worker.perform_now(transaction)
  end

  describe "resolving description" do
    it "sets the description to checkin if station category is check_in and action is topup" do
      allow(transaction.station).to receive(:category).and_return("check_in")
      expect(worker.perform_now(transaction).first.description).to eql("checkin")
    end

    it "sets the description to purchase if station category is box_office and action is topup" do
      allow(transaction.station).to receive(:category).and_return("box_office")
      expect(worker.perform_now(transaction).first.description).to eql("purchase")
    end

    it "removes _fee from description if action is in FEES" do
      description = Pokes::Credit::FEES.sample
      transaction.update!(action: description)
      expect(worker.perform_now(transaction).first.description).to eql(description.gsub("_fee", ""))
    end
  end

  describe "resolving action" do
    it "sets the action to purchase if action is in FEES" do
      transaction.update!(action: Pokes::Credit::FEES.sample)
      expect(worker.perform_now(transaction).first.action).to eql("fee")
    end

    it "sets the action to correction if action is in CORRECTIONS" do
      transaction.update!(action: Pokes::Credit::CORRECTIONS.sample)
      expect(worker.perform_now(transaction).first.action).to eql("correction")
    end

    it "sets the action to record_credit if action in ACTIONS" do
      transaction.update!(action: Pokes::Credit::ACTIONS.sample)
      expect(worker.perform_now(transaction).first.action).to eql("record_credit")
    end
  end

  describe "extracting credit values" do
    include_examples "a credit"

    it "sets credit_amount to one of transaction" do
      expect(@poke.credit_amount).to eql(2.2)
    end
  end
end
