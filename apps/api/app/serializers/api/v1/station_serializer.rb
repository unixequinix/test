class Api::V1::StationSerializer < Api::V1::BaseSerializer
  attributes :id, :type, :name

  def attributes(*args)
    hash = super
    method(object.form).call(hash) if object.form
    hash
  end

  def type
    object.category
  end

  def accreditation(hash)
    hash[:catalog] = object.station_catalog_items.map do |ci|
      { catalogable_id: ci.catalog_item.catalogable_id,
        catalogable_type: ci.catalog_item.catalogable_type.downcase,
        price: ci.price.round(2) }
    end
  end

  def pos(hash)
    hash[:products] = object.station_products.map do |sp|
      { product_id: sp.product_id,
        price: sp.price.round(2),
        position: sp.position }
    end
  end

  def topup(hash)
    hash[:top_up_credits] = object.topup_credits.map do |c|
      { amount: c.amount,
        price: (c.amount * c.credit.value).to_f.round(2) }
    end
  end

  def access(hash)
    hash[:entitlements] = {
      in: object.access_control_gates.where(direction: "1").pluck(:access_id),
      out: object.access_control_gates.where(direction: "-1").pluck(:access_id)
    }
  end
end
