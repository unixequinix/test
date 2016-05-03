class Api::V1::Events::TimeController < Api::V1::Events::BaseController
  def index
    render text: Time.now.strftime("%Y-%m-%d %T.%L")
  end
end
