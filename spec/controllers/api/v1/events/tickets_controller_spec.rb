
require "spec_helper"

RSpec.describe Api::V1::Events::TicketsController, type: :controller do
  let(:event) { create(:event) }
  let(:admin) { create(:admin) }
  let(:db_tickets) { event.tickets }

  before do
    create_list(:ticket, 2, :with_purchaser, event: event)
  end

  describe "GET index" do
    context "with authentication" do
      before(:each) do
        http_login(admin.email, admin.access_token)
        get :index, event_id: event.id
      end

      it "returns a 200 status code" do
        expect(response.status).to eq(200)
      end

      it "returns the necessary keys" do
        JSON.parse(response.body).map do |ticket|
          keys = %w(reference redeemed purchaser_first_name purchaser_last_name purchaser_email banned updated_at catalog_item_id customer_id) # rubocop:disable Metrics/LineLength
          expect(ticket.keys).to eq(keys)
        end
      end

      it "returns the correct data" do
        JSON.parse(response.body).each do |list_ticket|
          ticket = db_tickets[db_tickets.index { |t| t.code == list_ticket["reference"] }]
          expect(list_ticket["reference"]).to eq(ticket.code)
          expect(list_ticket["redeemed"]).to eq(ticket.redeemed)
          expect(list_ticket["banned"]).to eq(ticket.banned?)
          expect(list_ticket["customer_id"]).to eq(ticket&.customer&.id)
          updated_at = Time.zone.parse(list_ticket["updated_at"]).strftime("%Y-%m-%dT%T.%6N")
          expect(updated_at).to eq(ticket.updated_at.utc.strftime("%Y-%m-%dT%T.%6N"))
        end
      end
    end

    context "without authentication" do
      it "returns a 401 status code" do
        get :index, event_id: event.id
        expect(response.status).to eq(401)
      end
    end
  end

  describe "GET show" do
    context "with authentication" do
      before do
        @agreement = create(:company_event_agreement, event: event)
        @pack = create(:pack, :with_access)
        @access = @pack.catalog_items.accesses.first
        @ctt = create(:ticket_type, company_event_agreement: @agreement, event: event, catalog_item: @pack)
        @customer = create(:customer, event: event)
        @ticket = create(:ticket, event: event, ticket_type: @ctt, customer: @customer)
        order = create(:order, customer: @customer)
        @item = create(:order_item, order: order, catalog_item: @access, counter: 1)

        http_login(admin.email, admin.access_token)
      end

      describe "when ticket exists" do
        before(:each) do
          get :show, event_id: event.id, id: @ticket.code
        end

        it "returns a 200 status code" do
          expect(response.status).to eq(200)
        end

        it "returns the necessary keys" do
          ticket = JSON.parse(response.body)
          ticket_keys = %w(reference credential_redeemed banned catalog_item_id customer purchaser_first_name purchaser_last_name purchaser_email) # rubocop:disable Metrics/LineLength
          c_keys = %w(id credentials first_name last_name email orders)
          order_keys = %w(id catalog_item_id amount)
          credential_keys = %w(reference type)

          expect(ticket.keys).to eq(ticket_keys)
          expect(ticket["customer"].keys).to eq(c_keys)
          expect(ticket["customer"]["credentials"].map(&:keys).flatten.uniq).to eq(credential_keys)
          expect(ticket["customer"]["orders"].map(&:keys).flatten.uniq).to eq(order_keys)
        end

        it "returns the correct data" do
          customer = @ticket.customer

          ticket = {
            reference: @ticket.code,
            credential_redeemed: @ticket.redeemed,
            banned: @ticket.banned,
            catalog_item_id: @ticket.ticket_type.catalog_item.id,
            customer: {
              id:  @ticket.customer.id,
              credentials: [{ reference: @ticket.code, type: "ticket" }],
              first_name: customer.first_name,
              last_name: customer.last_name,
              email: customer.email,
              orders: [{
                id: @item.counter,
                catalog_item_id: @item.catalog_item_id,
                amount: @item.amount
              }]
            },
            purchaser_first_name: @ticket.purchaser_first_name,
            purchaser_last_name: @ticket.purchaser_last_name,
            purchaser_email: @ticket.purchaser_email
          }

          expect(JSON.parse(response.body)).to eq(ticket.as_json)
        end
      end

      describe "when ticket doesn't exist" do
        it "returns a 404 status code" do
          get :show, event_id: event.id, id: (db_tickets.last.id + 10)
          expect(response.status).to eq(404)
        end
      end
    end

    context "without authentication" do
      it "returns a 401 status code" do
        get :show, event_id: event.id, id: db_tickets.last.id
        expect(response.status).to eq(401)
      end
    end
  end
end
