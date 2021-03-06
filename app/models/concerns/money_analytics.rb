module MoneyAnalytics
  extend ActiveSupport::Concern
  include BaseAnalytics

  SALES_STATIONS = %w[bar vendor].freeze
  PURCHASES_ACTIONS = %w[topup purchase].freeze

  # Onsite Topups
  #
  def money_topups(grouping: :day, station_filter: [], payment_filter: [], operator_filter: [])
    monetary_topups(station_filter: station_filter, payment_filter: payment_filter, operator_filter: operator_filter).group_by_period(grouping, :date).sum(:monetary_total_price)
  end

  def money_topups_total(station_filter: [], payment_filter: [], operator_filter: [])
    monetary_topups(station_filter: station_filter, payment_filter: payment_filter, operator_filter: operator_filter).sum(:monetary_total_price)
  end

  # Online Orders
  #
  def money_online_orders_fee(grouping: :day, payment_filter: [])
    online_orders(payment_filter: payment_filter).group_by_period(grouping, :created_at).sum(:money_fee)
  end

  def money_online_orders_base(grouping: :day, payment_filter: [])
    online_orders(payment_filter: payment_filter).group_by_period(grouping, :created_at).sum(:money_base)
  end

  def money_online_orders(grouping: :day, payment_filter: [])
    online_orders(payment_filter: payment_filter).group_by_period(grouping, :created_at).sum("money_base + money_fee")
  end

  def money_online_orders_fee_total(payment_filter: [])
    online_orders(payment_filter: payment_filter).sum(:money_fee)
  end

  def money_online_orders_base_total(payment_filter: [])
    online_orders(payment_filter: payment_filter).sum(:money_base)
  end

  def money_online_orders_total(payment_filter: [])
    online_orders(payment_filter: payment_filter).sum("money_base + money_fee")
  end

  # Box Office
  #
  def money_box_office(grouping: :day, station_filter: [], payment_filter: [], catalog_filter: [])
    monetary_box_office(station_filter: station_filter, payment_filter: payment_filter, catalog_filter: catalog_filter).group_by_period(grouping, :date).sum(:monetary_total_price)
  end

  def count_money_box_office(grouping: :day, station_filter: [], payment_filter: [], catalog_filter: [])
    monetary_box_office(station_filter: station_filter, payment_filter: payment_filter, catalog_filter: catalog_filter).group_by_period(grouping, :date).count
  end

  def money_box_office_total(station_filter: [], payment_filter: [], catalog_filter: [])
    monetary_box_office(station_filter: station_filter, payment_filter: payment_filter, catalog_filter: catalog_filter).sum(:monetary_total_price)
  end

  # Online Refunds
  #
  def money_online_refunds_fee(grouping: :day, payment_filter: [])
    online_refunds(payment_filter: payment_filter).group_by_period(grouping, :created_at).sum("ABS(credit_fee * #{credit.value})")
  end

  def money_online_refunds_base(grouping: :day, payment_filter: [])
    online_refunds(payment_filter: payment_filter).group_by_period(grouping, :created_at).sum("ABS(credit_base * #{credit.value})")
  end

  def money_online_refunds(grouping: :day, payment_filter: [])
    online_refunds(payment_filter: payment_filter).group_by_period(grouping, :created_at).sum("ABS((credit_base + credit_fee)  * #{credit.value})")
  end

  def money_online_refunds_fee_total(payment_filter: [])
    online_refunds(payment_filter: payment_filter).sum("credit_fee * #{credit.value}").abs
  end

  def money_online_refunds_base_total(payment_filter: [])
    online_refunds(payment_filter: payment_filter).sum("credit_base * #{credit.value}").abs
  end

  def money_online_refunds_total(payment_filter: [])
    online_refunds(payment_filter: payment_filter).sum("(credit_base + credit_fee) * #{credit.value}").abs
  end

  # Onsite Refunds
  #
  def money_onsite_refunds(grouping: :day, station_filter: [], payment_filter: [])
    monetary_onsite_refunds(station_filter: station_filter, payment_filter: payment_filter).group_by_period(grouping, :date).sum("ABS(monetary_total_price)")
  end

  def money_onsite_refunds_total(station_filter: [], payment_filter: [])
    monetary_onsite_refunds(station_filter: station_filter, payment_filter: payment_filter).sum("ABS(monetary_total_price)")
  end

  # Refunds
  #
  def money_refunds(grouping: :day, station_filter: stations.where(category: TOPUPS_STATIONS))
    merge(money_online_refunds(grouping: grouping), money_onsite_refunds(grouping: grouping, station_filter: station_filter))
  end

  def money_refunds_total(station_filter: stations.where(category: TOPUPS_STATIONS))
    money_onsite_refunds_total(station_filter: station_filter) + money_online_refunds_total
  end

  # All Fees
  #
  def money_income_fees(grouping: :day, payment_filter: [])
    merge(money_online_orders_fee(grouping: grouping, payment_filter: payment_filter), money_online_refunds_fee(grouping: grouping, payment_filter: payment_filter))
  end

  def money_outcome_fees(*)
    {}
  end

  def money_fees(grouping: :day)
    merge_subtract(money_income_fees(grouping: grouping), money_outcome_fees(grouping: grouping))
  end

  def money_income_fees_total
    money_online_orders_fee_total + money_online_refunds_fee_total
  end

  def money_outcome_fees_total
    0
  end

  def money_fees_total
    money_income_fees_total - money_outcome_fees_total
  end

  # Income
  #
  def money_income(grouping: :day)
    merge(money_topups(grouping: grouping), money_box_office(grouping: grouping), money_online_orders_base(grouping: grouping), money_income_fees(grouping: grouping))
  end

  def money_income_total
    money_topups_total + money_box_office_total + money_online_orders_base_total + money_income_fees_total
  end

  # Outcome
  #
  def money_outcome(grouping: :day)
    merge(money_online_refunds(grouping: grouping), money_onsite_refunds_base(grouping: grouping), money_outcome_fees(grouping: grouping))
  end

  def money_outcome_total
    money_online_refunds_total + money_onsite_refunds_total + money_outcome_fees_total
  end

  # Outstanding
  #
  def money_outstanding(grouping: :day)
    merge_subtract(money_income(grouping: grouping), money_outcome(grouping: grouping))
  end

  def money_outstanding_total
    money_income_total - money_outcome_total
  end

  # Cash Recon
  #
  def cash_recon(operator_filter: [], station_filter: [], device_filter: [])
    pokes.where(action: "cash_recon", description: "close_shift").with_station(station_filter).with_operator(operator_filter).with_device(device_filter).is_ok
  end

  def money_cash_recon(grouping: :day, operator_filter: [], station_filter: [], device_filter: [])
    cash_recon(operator_filter: operator_filter, station_filter: station_filter, device_filter: device_filter).group_by_period(grouping, :date).sum(:monetary_total_price)
  end
end
