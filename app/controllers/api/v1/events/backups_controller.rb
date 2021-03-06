module Api
  module V1
    module Events
      class BackupsController < Api::V1::EventsController
        skip_before_action :set_event
        skip_before_action :event_auth

        def create
          keys = %i[device_uid backup_created_at backup].all? { |i| params[i] }
          render(status: :bad_request, json: { error: "params missing" }) && return unless keys

          secrets = Rails.application.secrets
          credentials = Aws::Credentials.new(secrets.s3_access_key_id, secrets.s3_secret_access_key)
          s3 = Aws::S3::Resource.new(region: 'eu-west-1', credentials: credentials)

          device = params[:device_uid].to_s.delete("\"")
          time = Time.zone.now.to_i
          name = "gspot/event/#{params[:event_id]}/backups/#{device}/#{time}.db"
          obj = s3.bucket(Rails.application.secrets.s3_bucket).object(name)
          obj.put(body: params[:backup])

          render(status: :created, json: :created)
        end
      end
    end
  end
end
