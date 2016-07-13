# == Schema Information
#
# Table name: profiles
#
#  id          :integer          not null, primary key
#  customer_id :integer
#  event_id    :integer          not null
#  deleted_at  :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  banned      :boolean          default(FALSE)
#

class Profile < ActiveRecord::Base # rubocop:disable Metrics/ClassLength
  acts_as_paranoid
  default_scope { order(created_at: :desc) }

  # Associations
  belongs_to :customer
  belongs_to :event
  has_many :orders
  has_many :claims
  has_many :refunds, through: :claims
  has_many :customer_orders
  has_many :online_orders, through: :customer_orders
  has_many :payments, through: :orders
  has_many :ban_transactions
  has_many :credit_transactions
  has_many :access_transactions
  has_many :credential_transactions
  has_many :money_transactions
  has_many :order_transactions
  has_many :customer_credits
  has_many :completed_claims, -> { where("aasm_state = 'completed' AND completed_at IS NOT NULL") },
           class_name: "Claim"
  has_many :credit_purchased_logs,
           -> { where(transaction_origin: CustomerCredit::CREDITS_PURCHASE) },
           class_name: "CustomerCredit"
  has_many :credential_assignments
  # credential_assignments_tickets
  has_many :ticket_assignments,
           -> { where(credentiable_type: "Ticket") },
           class_name: "CredentialAssignment", dependent: :destroy
  # credential_assignments_gtags
  has_many :gtag_assignments,
           -> { where(credentiable_type: "Gtag") },
           class_name: "CredentialAssignment", dependent: :destroy
  # credential_assignments_assigned
  has_many :active_assignments,
           -> { where(aasm_state: :assigned) }, class_name: "CredentialAssignment"
  # credential_assignments_tickets_assigned
  has_many :active_tickets_assignment,
           -> { where(aasm_state: :assigned, credentiable_type: "Ticket") },
           class_name: "CredentialAssignment"
  # credential_assignments_gtag_assigned
  has_one :active_gtag_assignment,
          -> { where(aasm_state: :assigned, credentiable_type: "Gtag") },
          class_name: "CredentialAssignment"
  has_one :completed_claim,
          -> { where(aasm_state: :completed) }, class_name: "Claim"
  has_many :payment_gateway_customers

  # Validations
  validates :event, presence: true

  # Scopes
  scope :for_event, -> (event) { where(event: event) }
  scope :with_gtag, lambda { |event|
    joins(:credential_assignments)
      .where(event: event,
             credential_assignments: { credentiable_type: "Gtag", aasm_state: :assigned })
  }

  scope :query_for_csv, lambda { |event|
    where(event: event)
      .joins("LEFT OUTER JOIN customers ON profiles.customer_id = customers.id")
      .joins(:customer_credits, :credential_assignments)
      .joins("INNER JOIN tickets
              ON credential_assignments.credentiable_id = tickets.id
              AND credential_assignments.aasm_state = 'assigned'
              AND credential_assignments.credentiable_type = 'Ticket'")
      .select("profiles.id, tickets.code as ticket, SUM(customer_credits.amount) as credits, customers.email,
               customers.first_name, customers.last_name")
      .group("profiles.id, customers.first_name, customers.id, tickets.code")
      .order("customers.first_name ASC")
  }

  def customer
    Customer.unscoped { super }
  end

  def all_transaction_counters
    indexes = credit_transactions.map(&:gtag_counter)
    indexes += access_transactions.map(&:gtag_counter)
    indexes += credential_transactions.map(&:gtag_counter)
    indexes += money_transactions.map(&:gtag_counter)
    indexes += order_transactions.map(&:gtag_counter)
    indexes += ban_transactions.map(&:gtag_counter)
    indexes.sort
  end

  def all_online_counters
    indexes = credit_transactions.map(&:counter)
    indexes += access_transactions.map(&:counter)
    indexes += credential_transactions.map(&:counter)
    indexes += money_transactions.map(&:counter)
    indexes += order_transactions.map(&:counter)
    indexes += ban_transactions.map(&:counter)
    indexes.sort
  end

  def missing_transaction_counters
    indexes = all_transaction_counters
    all_indexes = (1..indexes.last.to_i).to_a
    (all_indexes - indexes).sort
  end

  def active_credentials?
    active_tickets_assignment.any? || !active_gtag_assignment.nil?
  end

  # TODO: check with customer_credits.current method for duplication
  def current_balance
    customer_credits.order(created_in_origin_at: :desc).first
  end

  def total_credits
    customer_credits.sum(:amount)
  end

  def total_refundable
    customer_credits.sum(:refundable_amount)
  end

  def ticket_credits
    customer_credits.where.not(transaction_origin: CustomerCredit::CREDITS_PURCHASE)
                    .sum(:amount).floor
  end

  def purchased_credits
    customer_credits.where(transaction_origin: CustomerCredit::CREDITS_PURCHASE).sum(:amount).floor
  end

  def refundable_credits_amount
    current_balance.present? ? current_balance.final_refundable_balance : 0
  end

  # TODO: should this method be here??
  def refundable_money_amount
    refundable_credits_amount * event.standard_credit_price
  end

  def refundable_amount_after_fee(refund_service)
    fee = event.refund_fee(refund_service)
    refundable_money_amount - fee.to_f
  end

  def online_refundable_money_amount
    payments.sum(:amount)
  end

  def purchases
    customer_orders.joins(:catalog_item).select("sum(customer_orders.amount) as total_amount,
                                                 catalog_items.id,
                                                 catalog_items.name,
                                                 catalog_items.catalogable_type,
                                                 catalog_items.catalogable_id")
                   .group("catalog_items.name, catalog_items.catalogable_type, "\
             "catalog_items.catalogable_id, catalog_items.id")
  end

  def infinite_entitlements_purchased
    single = customer_orders.includes(catalog_item: :catalogable).select do |customer_order|
      customer_order.catalog_item.catalogable.try(:entitlement).try(:infinite?)
    end.map(&:catalog_item_id)

    packs_ids = Pack.joins(:catalog_items_included).where(catalog_items: { id: single })
    pack = CatalogItem.where(catalogable_id: packs_ids, catalogable_type: "Pack").pluck(:id)

    single + pack
  end

  def sorted_purchases(**params)
    Sorters::PurchasesSorter.new(purchases).sort(params)
  end

  def gateway_customer(gateway)
    payment_gateway_customers.find_by(gateway_type: gateway)
  end

  def self.counters(event) # rubocop:disable Metrics/MethodLength
    sql = <<-SQL
      SELECT to_json(json_agg(row_to_json(cust)))
      FROM (
        SELECT
          customer_trans.profile_id ,
          MAX(customer_trans.gtag_counter) as gtag,
          SUM(customer_trans.gtag_counter) as gtag_total,
          MAX(customer_trans.gtag_counter) * (MAX(customer_trans.gtag_counter) + 1) / 2 as gtag_last_total,
          MAX(customer_trans.counter) as online,
          SUM(customer_trans.counter) as online_total,
          MAX(customer_trans.counter) * (MAX(customer_trans.counter) + 1) / 2 as online_last_total
        FROM
        (
            SELECT
              profile_id,
              gtag_counter,
              counter
            FROM access_transactions
            WHERE event_id = #{event.id} AND status_code = 0
            UNION ALL
            SELECT
              profile_id,
              gtag_counter,
              counter
            FROM ban_transactions
            WHERE event_id = #{event.id} AND status_code = 0
            UNION ALL
            SELECT
              profile_id,
              gtag_counter,
              counter
            FROM credential_transactions
            WHERE event_id = #{event.id} AND status_code = 0
            UNION ALL
            SELECT
              profile_id,
              gtag_counter,
              counter
            FROM credit_transactions
            WHERE event_id = #{event.id} AND status_code = 0
            UNION ALL
            SELECT
              profile_id,
              gtag_counter,
              counter
            FROM money_transactions
            WHERE event_id = #{event.id} AND status_code = 0
            UNION ALL
            SELECT
              profile_id,
              gtag_counter,
              counter
            FROM order_transactions
            WHERE event_id = #{event.id} AND status_code = 0
        ) customer_trans
        GROUP BY customer_trans.profile_id
        ORDER BY customer_trans.profile_id
      ) cust
    SQL

    JSON.parse(ActiveRecord::Base.connection.select_value(sql)).to_a.group_by { |t| t["profile_id"] }
  end

  def self.customer_credits_sum(event) # rubocop:disable Metrics/MethodLength
    sql = <<-SQL
      SELECT to_json(json_agg(row_to_json(inc)))
      FROM (
        SELECT *
        FROM (
        	SELECT
        		sum(ccfl.amount) as credits_amount,
        		sum(ccfl.refundable_amount) as refundable_credits_amount,
        		last_final_balance,
        		last_final_refundable_balance,
        		last_final_balance - sum(ccfl.amount) as inconsistent,
        		last_final_refundable_balance - sum(ccfl.refundable_amount) as inconsistent_refundable,
        		ccfl.profile_id

        	FROM customer_credits ccfl
        	INNER JOIN (
        		SELECT
        		  ccf.id,
        		  ccf.final_balance as last_final_balance,
        		  ccf.final_refundable_balance as last_final_refundable_balance,
        		  cc.profile_id,
        		  max_gtag_counter,
        		  max_online_counter
        	    FROM (
        	      SELECT
        	        profile_id,
        	        MAX(gtag_counter) as max_gtag_counter,
        	        MAX(online_counter) as max_online_counter
        	      FROM customer_credits
        	      JOIN profiles
        	        ON customer_credits.profile_id = profiles.id
        	      WHERE profiles.event_id = #{event.id}
        	      GROUP BY profile_id
        	    ) cc
        	    INNER JOIN customer_credits ccf
        	      ON ccf.profile_id = cc.profile_id
        	      AND ccf.gtag_counter = cc.max_gtag_counter
        	      AND ccf.online_counter = cc.max_online_counter
        	) ccl
        	ON ccfl.profile_id = ccl.profile_id
        	GROUP BY last_final_balance, last_final_refundable_balance, ccfl.profile_id
        ) ccall
        WHERE last_final_balance <> credits_amount
        	OR last_final_refundable_balance <> refundable_credits_amount
        ORDER BY inconsistent DESC
      ) inc
    SQL
    JSON.parse(ActiveRecord::Base.connection.select_value(sql)).to_a
  end
end
