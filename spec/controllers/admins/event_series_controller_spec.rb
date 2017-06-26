require 'rails_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator.  If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails.  There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.
#
# Compared to earlier versions of this generator, there is very limited use of
# stubs and message expectations in this spec.  Stubs are only used when there
# is no simpler way to get a handle on the object needed for the example.
# Message expectations are only used when there is no simpler way to specify
# that an instance is receiving a specific message.
#
# Also compared to earlier versions of this generator, there are no longer any
# expectations of assigns and templates rendered. These features have been
# removed from Rails core in Rails 5, but can be added back in via the
# `rails-controller-testing` gem.

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
  before { sign_in(create(:user, role: "admin")) }

  describe "GET #index" do
    it "returns a success response" do
      EventSerie.create! valid_attributes
      get :index, params: {}
      expect(response).to be_success
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      event_serie = EventSerie.create! valid_attributes
      get :show, params: { id: event_serie.to_param }
      expect(response).to be_success
    end
  end

  describe "GET #new" do
    it "returns a success response" do
      get :new, params: {}
      expect(response).to be_success
    end
  end

  describe "GET #edit" do
    it "returns a success response" do
      event_serie = EventSerie.create! valid_attributes
      get :edit, params: { id: event_serie.to_param }
      expect(response).to be_success
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
        expect(response).to be_success
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
        expect(response).to be_success
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
end
