class Events::OrdersController < Events::BaseController
  before_action :check_top_ups_is_active!
  before_action :check_customer_has_credentials!

  def show
    @payment_service = params[:payment_service]
    @order = Order.includes(order_items: :catalog_item).find(params[:id])
    @payment_gateways = @current_event.payment_gateways.topup
  end

  def new
    @order = current_customer.orders.new
    @catalog_items = catalog_items_hash
  end

  def create # rubocop:disable Metrics/AbcSize
    catalog_items = params[:checkout_form][:catalog_items]
    @order = current_customer.orders.new
    @catalog_items = catalog_items_hash
    catalog_items.each do |item_id, amount|
      next unless amount.to_i.positive?
      item = @current_event.catalog_items.find(item_id)
      @order.order_items << OrderItem.new(catalog_item: item, amount: amount.to_i, total: amount.to_i * item.price)
    end

    if @order.total.positive? && @order.save
      redirect_to event_order_url(@current_event, @order)
    else
      flash.now[:error] = @order.errors.full_messages.to_sentence
      render :new
    end
  end

  private

  def catalog_items_hash
    portal_items = @current_event.portal_station.station_catalog_items
    CatalogItem.joins(:station_catalog_items)
               .select("catalog_items.*, station_catalog_items.price")
               .where.not(id: current_customer.infinite_entitlements_purchased)
               .where(station_catalog_items: { hidden: false, id: portal_items.ids })
               .includes(:event)
               .group_by(&:type)
  end
end
