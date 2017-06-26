require 'spec_helper'
require 'rails-controller-testing'

RSpec.describe Events::SessionsController, type: :controller do
  let(:event) { create(:event) }
  let(:customer) { create(:customer, event: event) }

  before(:each) { request.env["devise.mapping"] = Devise.mappings[:customer] }

  describe 'render template new' do
    context 'event has customer portal' do
      it 'GET login' do
        event.open_portal = true
        get :new, params: { event_id: event }
        expect(response).to be_ok
        expect(response).to render_template('new')
      end
    end

    context 'event has no customer portal' do
      it 'GET login' do
        event.open_portal = false
        get :new, params: { event_id: event }
        expect(response).to be_ok
        expect(response).to render_template('new')
      end
    end
  end
end
