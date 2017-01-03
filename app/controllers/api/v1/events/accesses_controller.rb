class Api::V1::Events::AccessesController < Api::V1::Events::BaseController
  before_action :set_modified

  def index
    accesses = @current_event.accesses.includes(:entitlement)
    accesses = accesses.where("catalog_items.updated_at > ?", @modified) if @modified
    date = accesses.maximum(:updated_at)&.httpdate
    accesses = accesses.map { |a| Api::V1::AccessSerializer.new(a) }.to_json if accesses.present?

    render_entity(accesses, date)
  end
end
