require "rails_helper"

RSpec.describe Pokes::Purchase, type: :job do
  let(:worker) { Pokes::Purchase }
  let(:event) { create(:event) }
  let(:access) { create(:access, event: event) }
  let(:transaction) { create(:money_transaction, action: "box_office_purchase", event: event, catalog_item: access) }

  describe ".stat_creation" do
    let(:action) { "purchase" }
    let(:name) { nil }

    include_examples "a poke"
  end

  describe "extracting purchase information" do
    context "portal_purchase action, " do
      let(:order) { create(:order, :with_different_items, event: event) }

      before do
        transaction.update! action: "portal_purchase", order: order, catalog_item: nil
      end

      it "creates as many pokes as order_items present" do
        expect { worker.perform_now(transaction) }.to change(Poke, :count).by(3)
      end

      it "differentiates pokes by line_counter" do
        pokes = worker.perform_now(transaction)
        expect(pokes.map(&:line_counter).sort).to eql([1, 2, 3])
      end

      it "names action purchase" do
        pokes = worker.perform_now(transaction)
        expect(pokes.map(&:action).sort).to eql(%w[purchase purchase purchase])
      end

      it "sets monetary_quantity to 1" do
        pokes = worker.perform_now(transaction)
        expect(pokes.map(&:monetary_quantity).uniq).to eql([1])
      end

      it "sets monetary_total_price to order_item price" do
        pokes = worker.perform_now(transaction)
        expect(pokes.sum(&:monetary_total_price).to_f).to eql(order.total.to_f)
      end

      it "sets monetary_unit_price to transaction price" do
        pokes = worker.perform_now(transaction)
        expect(pokes.sum(&:monetary_unit_price).to_f).to eql(order.total.to_f)
      end
    end

    context "box_office_purchase action, " do
      before { transaction.update action: "box_office_purchase" }
      let(:catalog_item) { transaction.catalog_item }

      include_examples "a catalog_item"
      include_examples "a money"
    end

    it "sets the payment_method of the transaction" do
      transaction.update!(payment_method: "test")
      poke = worker.perform_now(transaction)
      expect(poke.payment_method).to eql("test")
    end
  end
end
