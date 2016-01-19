module Companies
  module Api
    module V1
      class TicketTypeSerializer < Companies::Api::V1::BaseSerializer
        attributes :id, :name, :internal_ticket_type

        def internal_ticket_type
          object.code
        end
      end
    end
  end
end
