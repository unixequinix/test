require 'rails_helper'

RSpec.describe Admins::EventSeriesController, type: :controller do
  # This should return the minimal set of attributes required to create a valid
  # EventSerie. As you add validations to EventSerie, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) do
    { name: "foo" }
  end

  let(:invalid_attributes) do
    { name: nil }
  end

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # EventSerieController. Be sure to keep this updated too.
  before { sign_in(create(:user, role: :admin)) }

  describe "GET #index" do
    it "returns a success response" do
      EventSerie.create! valid_attributes
      get :index, params: {}
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      event_serie = EventSerie.create! valid_attributes
      get :show, params: { id: event_serie.to_param }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET #new" do
    it "returns a success response" do
      get :new, params: {}
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET #edit" do
    it "returns a success response" do
      event_serie = EventSerie.create! valid_attributes
      get :edit, params: { id: event_serie.to_param }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new EventSerie" do
        expect do
          post :create, params: { event_serie: valid_attributes }
        end.to change(EventSerie, :count).by(1)
      end

      it "redirects to the created event_series" do
        post :create, params: { event_serie: valid_attributes }
        expect(response).to redirect_to([:admins, EventSerie.last])
      end
    end

    context "with invalid params" do
      it "returns a success response (i.e. to display the 'new' template)" do
        post :create, params: { event_serie: invalid_attributes }
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) { { name: "test" } }

      it "updates the requested event_series" do
        event_serie = EventSerie.create! valid_attributes
        put :update, params: { id: event_serie.to_param, event_serie: new_attributes }
        event_serie.reload
        expect(event_serie.name).to eql("test")
      end

      it "redirects to the event_series" do
        event_serie = EventSerie.create! valid_attributes
        put :update, params: { id: event_serie.to_param, event_serie: valid_attributes }
        expect(response).to redirect_to(admins_event_series_path)
      end
    end

    context "with invalid params" do
      it "returns a success response (i.e. to display the 'edit' template)" do
        event_serie = EventSerie.create! valid_attributes
        put :update, params: { id: event_serie.to_param, event_serie: invalid_attributes }
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested event_series" do
      event_serie = EventSerie.create! valid_attributes
      expect do
        delete :destroy, params: { id: event_serie.to_param }
      end.to change(EventSerie, :count).by(-1)
    end

    it "redirects to the event_series list" do
      event_serie = EventSerie.create! valid_attributes
      delete :destroy, params: { id: event_serie.to_param }
      expect(response).to redirect_to(admins_event_series_index_url)
    end
  end

  describe "GET #copy_data" do
    it "returns a success response" do
      event_serie = create(:event_serie)

      get :copy_data, params: { id: event_serie.id }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST #copy_serie" do
    before(:each) do
      @current_event = create(:event)
      @base_event = create(:event)
      @event_serie = create(:event_serie, :with_events, associated_events: [@current_event, @base_event])
    end

    context "with valid params" do
      it "returns a success response" do
        post :copy_serie, params: { id: @event_serie.id, copy_data: { customers: "1 0", new_id: @current_event.id, old_id: @base_event.id } }
        expect(response).to redirect_to admins_event_series_path(@event_serie)
      end
    end

    context "with invalid params" do
      it "returns a success response" do
        post :copy_serie, params: { id: @event_serie.id, copy_data: { customers: "1 0", new_id: @current_event.id, old_id: @current_event.id } }
        expect(response).to redirect_to copy_data_admins_event_series_path(@event_serie)
      end
    end
  end
end
