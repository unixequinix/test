require "rails_helper"

RSpec.describe Api::V1::Events::CustomersController, type: :controller do
  let(:event) { create(:event) }
  let(:admin) { create(:admin) }
  let(:profile) { create(:profile, event: event) }
  let(:item) { create(:catalog_item, :with_access, event: event) }
  let(:db_profiles) { event.profiles }

  describe "GET index" do
    context "with authentication" do
      before do
        create(:credential_assignment_g_a, profile: profile)
        order = create(:customer_order, profile: profile, catalog_item: item)
        create(:online_order, customer_order: order, redeemed: false)
      end

      before(:each) do
        http_login(admin.email, admin.access_token)
        get :index, event_id: event.id
      end

      it "returns a 200 status code" do
        expect(response.status).to eq(200)
      end

      it "returns the necessary keys" do
        cus_keys = %w(id banned updated_at first_name last_name email credentials orders autotopup_gateways)
        cre_keys = %w(profile_id reference type)
        order_keys = %w(profile_id online_order_counter amount catalogable_id catalogable_type)

        JSON.parse(response.body).map do |gtag|
          expect(gtag.keys).to eq(cus_keys)
          expect(gtag["credentials"].map(&:keys).flatten.uniq).to eq(cre_keys)
          expect(gtag["orders"].map(&:keys).flatten.uniq).to eq(order_keys)
        end
      end

      it "returns the correct reference of the credentiable" do
        JSON.parse(response.body).map do |c|
          api_cred = c["credentials"]
          profile_cred = Profile.find(c["id"]).credential_assignments.where(aasm_state: "assigned")
          db_cred = profile_cred.map do |obj|
            if obj.credentiable_type == "Ticket"
              { profile_id: obj.profile_id, reference: obj.credentiable.code, type: "ticket" }.as_json
            else
              { profile_id: obj.profile_id, reference: obj.credentiable.tag_uid, type: "gtag" }.as_json
            end
          end
          expect(api_cred).to eq(db_cred)
        end
      end
    end

    context "without authentication" do
      it "has a 401 status code" do
        get :index, event_id: event.id
        expect(response.status).to eq(401)
      end
    end
  end
end