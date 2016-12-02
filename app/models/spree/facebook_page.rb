module Spree
  class FacebookPage < ActiveRecord::Base

    class << self
      include Spree::Core::Engine.routes.url_helpers
    end

    belongs_to :account, class_name: 'Spree::FacebookAccount', foreign_key: :account_id

    validates :page_id, uniqueness: {message: 'has already been added'}
    before_validation :get_and_assing_page_access_token
    after_initialize :set_koala_client, if: :page_token?

    attr_accessor :client

    def post(message, image = nil)
      if image
        image_binary = image.get_image_binary
        post_image(image_binary, message)
      else
        post_message(message)
      end
    end

    private
      def set_koala_client
        self.client = Koala::Facebook::API.new(self.page_token)
      end

      def post_message(message)
        client.put_connections(self.page_id, 'feed', message: message)
      end

      def post_image(source_binary, caption = '')
        client.put_picture(source_binary, 'multipart/form-data', {message: caption}, self.page_id)
      end

      def get_and_assing_page_access_token
        page_access_token_uri = URI("https://graph.facebook.com/#{ page_id }")
        page_access_token_uri.query = URI.encode_www_form(access_token: account.auth_token, fields: 'access_token')
        response = Net::HTTP.get_response(page_access_token_uri)
        response_json = JSON.parse(response.body)
        if response.code == '200'
          self.page_token = response_json['access_token']
        else
          errors.add(:base, response_json['error']['message'])
        end
      end
  end
end