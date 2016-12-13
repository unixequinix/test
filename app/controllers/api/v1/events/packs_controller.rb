class Api::V1::Events::PacksController < Api::V1::Events::BaseController
  before_action :set_modified

  def index
    packs = current_event.packs.includes(pack_catalog_items: :catalog_item)
    packs = packs.where("catalog_items.updated_at > ?", @modified) if @modified
    date = packs.maximum(:updated_at)&.httpdate
    packs = ActiveModelSerializers::Adapter.create(packs.map { |a| Api::V1::PackSerializer.new(a) }).to_json if packs.present? # rubocop:disable Metrics/LineLength

    render_entity(packs, date)
  end
end
