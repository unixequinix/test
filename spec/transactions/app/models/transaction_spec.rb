require "rails_helper"

RSpec.describe Transaction, type: :model do
  let(:transaction) { build(:transaction) }

  it { is_expected.to validate_presence_of(:transaction_type) }

  context ".write" do
    let(:klass) { MonetaryTransaction }
    let(:atts) { { transaction_type: "refund", amount: 2.2 } }
    subject(:result) { Transaction.write("monetary", atts) }

    it { is_expected.to be_a_kind_of(klass) }
    it { is_expected.not_to be_new_record }

    it "calls .pre_process" do
      expect(klass).to receive(:pre_process).with(atts).and_return(atts)
      Transaction.write("monetary", atts)
    end

    it "writes the parameters passed" do
      expect(result.amount).to eq(2.2)
    end

    it "should call asynchronously .execute_actions" do
      expect(klass.method :execute_actions).to be_delayed(result.id)
    end
  end

  context ".execute_actions" do
    let(:transaction) { MonetaryTransaction.create transaction_type: "refund" }

    before :each do
      allow(Transaction).to receive(:find) { transaction }
    end

    it "calls the subcribed methods on the appropiate instance" do
      actions = [MonetaryTransaction::SUBSCRIPTIONS[:refund]].flatten
      actions.each { |action| expect(transaction).to receive(action) }
      Transaction.execute_actions(transaction.id)
    end
  end
end
