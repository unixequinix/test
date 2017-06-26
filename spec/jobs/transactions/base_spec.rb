require "rails_helper"

RSpec.describe Transactions::Base, type: :job do
  let(:base)  { Transactions::Base }
  let(:event) { create(:event) }
  let(:gtag)  { create(:gtag, tag_uid: "AAAAAAAAAAAAAA", event: event) }
  let(:customer) { create(:customer, event: event) }
  let(:params) do
    {
      type: "credit",
      action: "sale",
      credits: 30,
      event_id: event.id,
      device_created_at: Time.zone.now.to_s,
      customer_tag_uid: gtag.tag_uid,
      status_code: 0
    }
  end

  describe "creates anonymous customers" do
    it "if not present" do
      gtag.update customer: nil
      expect { base.perform_now(params) }.to change(Customer, :count).by(1)
    end

    it "unless already present" do
      gtag.update! customer: customer
      expect { base.perform_now(params) }.not_to change(Customer, :count)
    end

    it ", then adds customer_id to transaction, even if already present" do
      gtag.update! customer: customer
      expect(Transactions::Credit::BalanceUpdater).to receive(:perform_later).once.with(hash_including(customer_id: customer.id))
      base.perform_now(params)
    end

    it ", then adds customer_id to transaction, event when not present in db" do
      gtag.update! customer: nil
      expect(Transactions::Credit::BalanceUpdater).to receive(:perform_later).once.with(hash_including(:customer_id))
      base.perform_now(params)
    end

    it "assigns any customer to the gtag" do
      gtag.update customer: nil
      base.perform_now(params)
      expect(gtag.reload.customer).not_to be_nil
    end
  end

  describe "when sale_items_attributes is blank" do
    after do
      expect { base.perform_now(params) }.to change(Transaction, :count).by(1)
    end

    it "works when status code is error (other than 0)" do
      params[:status_code] = 2
    end

    it "removes sale_item_attributes when empty" do
      params[:sale_item_attributes] = []
    end

    it "removes sale_item_attributes when nil" do
      params[:sale_item_attributes] = nil
    end
  end

  describe "when passed sale_items in attributes" do
    before do
      params.merge!(sale_items_attributes: [{ product_id: create(:product).id, quantity: 1.0, unit_price: 8.31 },
                                            { product_id: create(:product).id, quantity: 1.0, unit_price: 2.72 }])
    end

    it "saves sale_items" do
      expect { base.perform_now(params) }.to change(SaleItem, :count).by(2)
    end
  end

  context "when tag_uid is present in DB" do
    it "does not create a Gtag" do
      event.gtags << gtag
      expect { base.perform_now(params) }.not_to change(Gtag, :count)
    end
  end

  context "when tag_uid is not present in DB" do
    it "creates a Gtag for the event" do
      params[:customer_tag_uid] = "BBBBBBBBBBBBBB"
      expect { base.perform_now(params) }.to change(Gtag, :count).by(1)
    end
  end

  describe "descendants" do
    it "executes the job defined by action" do
      expected_atts = { action: "sale", event_id: event.id, type: "CreditTransaction", credits: 30, customer_tag_uid: gtag.tag_uid, status_code: 0 }
      params[:action] = "sale"
      expect(Transactions::Credit::BalanceUpdater).to receive(:perform_later).once.with(hash_including(expected_atts))
      base.perform_now(params)
    end

    it "must be loaded with environment" do
      expect(base.descendants).not_to be_empty
    end

    it "should include the descendants of base classes" do
      expect(base.descendants).to include(Transactions::Credential::TicketChecker)
      expect(base.descendants).to include(Transactions::Credential::GtagChecker)
      expect(base.descendants).to include(Transactions::Credit::BalanceUpdater)
    end
  end

  context "creating transactions" do
    describe "from devices" do
      it "ignores attributes not present in table" do
        expect do
          base.perform_now(params.merge(foo: "not valid"))
        end.to change(CreditTransaction, :count).by(1)
      end

      it "works even if jobs fail" do
        params[:action] = "sale"
        allow(Transactions::Credit::BalanceUpdater).to receive(:perform_later).and_raise("Error_1")
        expect { base.perform_now(params) }.to raise_error("Error_1")
        params.delete(:transaction_id)
        params.delete(:customer_id)
        params.delete(:device_created_at)
        params.delete(:type)

        expect(CreditTransaction.where(params)).not_to be_empty
      end
    end
  end

  context "executing subscriptors" do
    it "should only execute subscriptors if the transaction created is new" do
      params[:action] = "sale"
      expect(Transactions::Credit::BalanceUpdater).to receive(:perform_later).once
      base.perform_now(params)
      at = params.merge(type: "credit", device_created_at: params[:device_created_at])
      base.perform_now(at)
    end
  end
end
