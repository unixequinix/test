module Admins
  module Events
    class AnalyticsController < Admins::Events::BaseController
      include EventsHelper
      include AnalyticsHelper

      before_action :authorize_billing

      def show # rubocop:disable Metrics/AbcSize
        @message = analytics_message(@current_event)
        totals = {}
        totals[:subtotals] = { money: {}, credits: {} }

        orders_dashboard = Order.dashboard(@current_event)
        pokes_dashboard = Poke.dashboard(@current_event)
        refunds_dashboard = Refund.dashboard(@current_event)
        refunds_dashboard[:money_reconciliation] = refunds_dashboard[:credits_breakage] * @credit_value

        kpis = [orders_dashboard, pokes_dashboard, refunds_dashboard]
        @kpis = formater(grouper(kpis))

        totals[:totals_pokes] = Poke.totals(@current_event)
        totals[:totals_orders] = Order.totals(@current_event)
        totals[:totals_refunds] = Refund.totals(@current_event)

        source_action_money = totals[:totals_pokes][:source_action_money] + totals[:totals_orders][:source_action_money] + totals[:totals_refunds][:source_action_money]
        totals[:subtotals][:money_highlight] = transformer(source_action_money.map { |t| { "dm1" => t['action'], "dm2" => t['source'], "metric" => t['money'] } }, "currency", @customers).sort_by { |t| -t["t"] }
        source_payment_method_money = totals[:totals_pokes][:source_payment_method_money] + totals[:totals_orders][:source_payment_method_money] + totals[:totals_refunds][:source_payment_method_money]
        totals[:subtotals][:money][:money_by_payment_method] = transformer(source_payment_method_money.map { |t| { "dm1" => t['source'], "dm2" => t['payment_method'], "metric" => t['money'] } }, "currency", @customers).sort_by { |t| -t["t"] }
        action_station_type_money = totals[:totals_pokes][:action_station_type_money] + totals[:totals_orders][:action_station_type_money] + totals[:totals_refunds][:action_station_type_money]
        totals[:subtotals][:money][:money_by_station_type] = transformer(action_station_type_money.map { |t| { "dm1" => t['action'], "dm2" => t['station_type'], "metric" => t['money'] } }, "currency", @customers).sort_by { |t| -t["t"] }
        totals[:totals_pokes][:event_day_money] = PokesQuery.new(@current_event).event_day_money

        totals[:subtotals][:credits][:credits_flow] = transformer(totals[:totals_pokes][:credits_flow].map { |t| { "dm1" => t[:action], "dm2" => t[:description], "metric" => t[:credits] } }, "token", @customers).sort_by { |t| -t["t"] }
        totals[:subtotals][:credits][:credits_type] = transformer(totals[:totals_pokes][:credits_type].map { |t| { "dm1" => t[:action], "dm2" => t[:credit_name], "metric" => t[:credits] } }, "token", @customers).sort_by { |t| -t["t"] }
        @totals = totals
      end

      def money
        online_purchase = @current_event.orders.online_purchase
        onsite_money = @current_event.pokes.money_recon
        online_refunds = @current_event.refunds.online_refund.each { |o| o.money = o.money * @credit_value }
        money_cols = ["Action", "Description", "Location", "Station Type", "Station Name", "Money", "Payment Method", "Event Day"]
        money = prepare_pokes(money_cols, onsite_money + online_purchase + online_refunds)

        totals = Poke.money_dashboard(@current_event)
        totals = totals.merge(Order.money_dashboard(@current_event))

        totals[:money_reconciliation] = totals[:money_reconciliation] + totals[:income_online]

        @totals = totals.reject { |_k, v| v == 0 }.map { |k, v| [k, number_to_event_currency(v)] }

        @views = [
          { chart_id: "money", title: "Money Flow", cols: ["Payment Method"], rows: ["Action"], data: money, metric: ["Money"], decimals: 1 },
          { chart_id: "money_by_stations", title: "Money Flow by Stations", cols: ["Event Day", "Payment Method"], rows: ["Location", "Station Type", "Station Name", "Action"], data: money, metric: ["Money"], decimals: 1 }
        ]
        prepare_data(params["action"])
      end

      def cashless
        record_credit = @current_event.pokes.where(credit: @current_event.credit).record_credit.is_ok.sum(:credit_amount)
        record_credit_virtual = @current_event.pokes.where(credit: @current_event.virtual_credit).record_credit.is_ok.sum(:credit_amount)
        fees = - @current_event.pokes.fees.is_ok.sum(:credit_amount)
        orders = @current_event.pokes.online_orders.is_ok.sum(:credit_amount)

        cols = ["Action", "Description", "Location", "Station Type", "Station Name", "Credit Name", "Credits", "Device", "Event Day"]
        credits_onsite = @current_event.pokes.credit_flow
        credits_orders = @current_event.orders.online_credits
        credits = prepare_pokes(cols, credits_onsite + credits_orders)

        @totals = { record_credit: record_credit, record_credit_virtual: record_credit_virtual, fees: fees, orders: orders }.map { |k, v| [k, number_to_token(v)] }
        @views = [
          { chart_id: "credits", title: "Credit Flow", cols: ["Event Day", "Credit Name"], rows: %w[Action Description], data: credits, metric: ["Credits"], decimals: 1 },
          { chart_id: "credits_detail", title: "Credit Flow by Station", cols: ["Event Day", "Credit Name"], rows: ["Location", "Action", "Station Type", "Station Name"], data: credits, metric: ["Credits"], decimals: 1 }
        ]
        prepare_data(params["action"])
      end

      def sales
        sale_credit = -@current_event.pokes.where(credit: @current_event.credit).sales.is_ok.sum(:credit_amount)
        sale_virtual = -@current_event.pokes.where(credit: @current_event.virtual_credit).sales.is_ok.sum(:credit_amount)
        total_sale = -@current_event.pokes.where(credit: @current_event.credits).sales.is_ok.sum(:credit_amount)

        cols = ["Description", "Location", "Station Type", "Station Name", "Product Name", "Credit Name", "Credits", "Event Day", "Operator UID", "Operator Name", "Device"]
        products = prepare_pokes(cols, @current_event.pokes.products_sale)
        stock_cols = ["Description", "Location", "Station Type", "Station Name", "Product Name", "Quantity", "Event Day", "Operator UID", "Operator Name", "Device"]
        products_stock = prepare_pokes(stock_cols, @current_event.pokes.products_sale_stock)

        @totals = { sale_credit: sale_credit, sale_virtual: sale_virtual, total_sale: total_sale }.map { |k, v| [k, number_to_token(v)] }
        @views = [
          { chart_id: "products", title: "Products Sale", cols: ["Event Day", "Credit Name"], rows: ["Location", "Station Type", "Station Name", "Product Name"], data: products, metric: ["Credits"], decimals: 1 },
          { chart_id: "products_stock", title: "Products Sale Stock", cols: ["Event Day"], rows: ["Location", "Station Type", "Station Name", "Product Name"], data: products_stock, metric: ["Quantity"], decimals: 0 }
        ]
        prepare_data(params["action"])
      end

      def gates
        total_checkins = @current_event.tickets.where(redeemed: true).count
        total_access = @current_event.pokes.sum(:access_direction)
        activations = @current_event.customers.count
        staff = @current_event.customers.where(operator: true).count

        rate_cols = ["Ticket Type", "Total Tickets", "Redeemed"]
        checkin_rate = prepare_pokes(rate_cols, @current_event.ticket_types.checkin_rate)
        ticket_cols = ["Action", "Description", "Location", "Station Type", "Station Name", "Catalog Item", "Ticket Type", "Total Tickets", "Event Day", "Operator UID", "Operator Name", "Device"]
        checkin_ticket_type = prepare_pokes(ticket_cols, @current_event.pokes.checkin_ticket_type)
        access_cols = ["Location", "Station Type", "Station Name", "Event Day", "Date Time", "Direction", "Access"]
        access_control = prepare_pokes(access_cols, @current_event.pokes.access)

        @totals = { total_checkins: total_checkins, total_access: total_access, activations: activations, staff: staff }.map { |k, v| [k, v.to_i] }
        @views = [{ chart_id: "checkin_rate", title: "Ticket Check-in Rate", cols: [], rows: ["Ticket Type", "Redeemed"], data: checkin_rate, metric: ["Total Tickets"], decimals: 0 },
                  { chart_id: "checkin_ticket_type", title: "Check-in and Box office purchase", cols: ["Event Day"], rows: ["Station Name", "Catalog Item"], data: checkin_ticket_type, metric: ["Total Tickets"], decimals: 0 },
                  { chart_id: "access_control", title: "Access Control", cols: ["Station Name", "Direction"], rows: ["Event Day", "Date Time"], data: access_control, metric: ["Access"], decimals: 0 }]
        prepare_data(params["action"])
      end

      private

      def authorize_billing
        authorize(@current_event, :analytics?)
        @load_analytics_resources = true
        @credit_value = @current_event.credit.value
        @customers = @current_event.customers.count - @current_event.customers.where(operator: true).count
      end

      def prepare_data(name)
        @name = name
        respond_to do |format|
          format.js { render action: :load_view }
        end
      end
    end
  end
end
