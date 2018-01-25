require 'rails_helper'

RSpec.describe Api::V2::Events::RefundsController, type: %i[controller api] do
  let(:event) { create(:event, open_api: true, state: "created") }
  let(:user) { create(:user) }
  let(:customer) { create(:customer, event: event) }
  let(:refund) { create(:refund, event: event, customer: customer) }

  let(:invalid_attributes) { { amount: nil } }
  let(:valid_attributes) { { amount: 100, status: "started", fields: { iban: "barrr", swift: "fooo" }, customer_id: customer.id, gateway: "paypal" } }

  before { token_login(user, event) }

  describe "GET #index" do
    before { create_list(:refund, 10, event: event) }

    it "returns a success response" do
      get :index, params: { event_id: event.id }
      expect(response).to have_http_status(:ok)
    end

    it "returns all refunds" do
      get :index, params: { event_id: event.id }
      expect(json.size).to be(10)
    end

    it "does not return refunds from another event" do
      new_refund = create(:refund)
      get :index, params: { event_id: event.id }
      expect(json).not_to include(obj_to_json_v2(new_refund, "RefundSerializer"))
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      get :show, params: { event_id: event.id, id: refund.to_param }
      expect(response).to have_http_status(:ok)
    end

    it "returns the refund as JSON" do
      get :show, params: { event_id: event.id, id: refund.to_param }
      expect(json).to eq(obj_to_json_v2(refund, "RefundSerializer"))
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Refund" do
        expect do
          post :create, params: { event_id: event.id, refund: valid_attributes }
        end.to change(Refund, :count).by(1)
      end

      it "returns a created response" do
        post :create, params: { event_id: event.id, refund: valid_attributes }
        expect(response).to be_created
      end

      it "returns the created refund" do
        post :create, params: { event_id: event.id, refund: valid_attributes }
        expect(json["id"]).to eq(Refund.last.id)
      end
    end

    context "with invalid params" do
      it "returns an unprocessable_entity response" do
        post :create, params: { event_id: event.id, refund: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) { { gateway: "bank_account" } }

      before { refund }

      it "updates the requested refund" do
        expect do
          put :update, params: { event_id: event.id, id: refund.to_param, refund: new_attributes }
        end.to change { refund.reload.gateway }.to("bank_account")
      end

      it "returns the refund" do
        put :update, params: { event_id: event.id, id: refund.to_param, refund: valid_attributes }
        expect(json["id"]).to eq(refund.id)
      end
    end

    context "with invalid params" do
      it "returns an unprocessable_entity response" do
        put :update, params: { event_id: event.id, id: refund.to_param, refund: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE #destroy" do
    before do
      refund
      user.admin!
    end

    it "destroys the requested refund" do
      expect do
        delete :destroy, params: { event_id: event.id, id: refund.to_param }
      end.to change(Refund, :count).by(-1)
    end

    it "returns a success response" do
      delete :destroy, params: { event_id: event.id, id: refund.to_param }
      expect(response).to have_http_status(:ok)
    end
  end
end
