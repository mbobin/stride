module Stride
  class UserMessage
    def initialize(access_token, cloud_id, user_id, message_body)
      self.access_token = access_token
      self.cloud_id     = cloud_id
      self.user_id      = user_id
      self.message_body = message_body
    end

    def send!
      UserInstallationRequest.new(access_token, cloud_id, user_id).json
      Request.new(access_token, cloud_id, user_id, message_body).json
    end

    private

    attr_accessor :access_token, :cloud_id, :user_id, :message_body

    class UserInstallationRequest < AuthorizedRequest
      def initialize(access_token, cloud_id, user_id)
        self.access_token = access_token
        self.cloud_id     = cloud_id
        self.user_id      = user_id
      end

      private

      attr_accessor :cloud_id, :user_id

      def uri
        URI(
          "#{Stride.configuration.api_base_url}/site/#{cloud_id}/conversation/user/#{user_id}"
        )
      end

      def request_class
        Net::HTTP::Get
      end
    end

    class Request < AuthorizedRequest
      def initialize(access_token, cloud_id, user_id, message_body)
        self.access_token = access_token
        self.cloud_id     = cloud_id
        self.user_id      = user_id
        self.message_body = message_body
      end

      private

      attr_accessor :cloud_id, :user_id, :message_body

      def uri
        URI(
          "#{Stride.configuration.api_base_url}/site/#{cloud_id}/conversation/user/#{user_id}/message"
        )
      end

      def params
        message_body
      end
    end
  end
end
