require "rails_helper"

RSpec.describe Api::V1::Events::CustomersController, type: :controller do
  let(:admin) { Admin.first || FactoryGirl.create(:admin) }

  before(:all) do
    @event = Event.last || create(:event)
    @customer = create(:customer_event_profile, event: @event)
    create(:credential_assignment_g_a, customer_event_profile: @customer)
    create_list(:customer_order,
                5,
                customer_event_profile: @customer,
                catalog_item: create(:catalog_item, :with_access, event: @event))
  end

  describe "GET index" do
    context "with authentication" do
      before(:each) do
        http_login(admin.email, admin.access_token)
      end

      it "has a 200 status code" do
        get :index, event_id: @event.id
        expect(response.status).to eq 200
      end

      context "when the If-Modified-Since header is sent" do
        it "returns only the modified customers" do
          @new_customer = create(:customer_event_profile, event: @event)
          @new_customer.update!(updated_at: Time.now + 4.hours)

          request.headers["If-Modified-Since"] = (@new_customer.updated_at - 2.hours)

          get :index, event_id: @event.id
          expect(JSON.parse(response.body).map { |m| m["id"] }).to eq([@new_customer.id])
        end
      end

      context "when the If-Modified-Since header isn't sent" do
        before do
          create(:customer_event_profile, event: @event)
        end

        it "returns the cached customers" do
          get :index, event_id: @event.id
          customers = JSON.parse(response.body).map { |m| m["id"] }
          cache_c = JSON.parse(Rails.cache.fetch("v1/event/#{@event.id}/customers")).map do |m|
            m["id"]
          end

          create(:customer_event_profile, event: @event)
          event_customers = @event.customer_event_profiles.map(&:id)

          expect(customers).to eq(cache_c)
          expect(customers).not_to eq(event_customers)
        end
      end
    end

    context "without authentication" do
      it "has a 401 status code" do
        get :index, event_id: @event.id
        expect(response.status).to eq 401
      end
    end
  end
end
