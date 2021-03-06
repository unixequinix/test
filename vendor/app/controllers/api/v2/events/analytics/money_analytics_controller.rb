module Api::V2
  module Events
    module Analytics
      class MoneyAnalyticsController < BaseAnalyticsController
        # GET api/v2/events/:event_id/analytics/money
        def index
          render json: parse_response
        end

        private

        def parse_response
          @results
        end
      end
    end
  end
end
