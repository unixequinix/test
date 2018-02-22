class Pokes::Purchase < Pokes::Base
  include PokesHelper

  TRIGGERS = %w[box_office_purchase portal_purchase].freeze

  def perform(t)
    atts = extract_money_atts(t, action: "purchase")
    item_atts = extract_catalog_item_info(t.catalog_item, atts)

    return create_poke(extract_atts(t, item_atts)) if t.catalog_item
    return unless t.order

    t.order.order_items.map.with_index do |item, index|
      item_atts = atts.merge(monetary_unit_price: t.order.money_base, monetary_total_price: t.order.money_base, line_counter: index + 1)
      item_atts.merge! extract_catalog_item_info(item.catalog_item, item_atts)
      create_poke(extract_atts(t, item_atts))
    end
  end
end
