class Api::V1::Events::TransactionsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :restrict_access_with_http

  def create # rubocop:disable Metrics/CyclomaticComplexity
    render(status: :bad_request, json: :bad_request) && return unless params[:_json]
    errors = { atts: [], jobs: [] }

    params[:_json].each_with_index do |atts, index|
      att_errors = validate_params(atts.keys, atts[:transaction_category], index)
      errors[:atts] << att_errors && next if att_errors
      errors[:jobs] << validate_jobs(atts, index)
    end

    errors.delete_if { |_, v| v.compact.empty? }
    render(status: :unprocessable_entity, json: { errors: errors }) && return if errors.any?
    render(status: :created, json: :created)
  end

  private

  def validate_params(keys, category, index)
    return [:category] unless category
    mandatory = "#{category.camelcase}Transaction".constantize.mandatory_fields
    missing = (mandatory.map(&:to_sym) - keys.map(&:to_sym)).to_sentence
    "Missing keys for position #{index}: #{missing}" unless missing.blank?
  end

  def validate_jobs(atts, index)
    obj = Jobs::Base.write(ActiveSupport::HashWithIndifferentAccess.new(atts))
    "#{obj.class.to_s.underscore.humanize} position #{index} not valid" unless obj.valid?
  end
end
