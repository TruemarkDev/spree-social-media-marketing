module Spree
  class TwitterAccount < SocialMediaAccount
    require 'twitter'

    has_many :posts, as: :social_media_publishable, class_name: 'Spree::SocialMediaPost', dependent: :destroy

    has_many :social_media_events_accounts, as: :social_media_marketing_account, dependent: :destroy
    has_many :social_media_events, through: :social_media_events_accounts, source: :social_media_marketing_event

    MESSAGE_MAXIMUM_LENGTH = 240

    Spree::TwitterAccount::IMAGE_LIMIT = 4
    attr_accessor :client

    def post(tweet, images = [])
      if images.present?
        first_four_images = images[0, Spree::TwitterAccount::IMAGE_LIMIT]
        image_binaries = first_four_images.map(&:get_image_binary)
        response = post_tweet_with_media(tweet, image_binaries)
      else
        response = post_tweet(tweet)
      end
      response.id
    end

    def remove_post(post_id)
      set_twitter_client
      begin
        client.destroy_status(post_id)
      rescue Twitter::Error::ClientError => e
        Rails.logger.error("Twitter Remove Post Error For PostId: #{ post_id }\n#{ e.message }\n")
      end
    end

    def display_account_name
      'Twitter'
    end

    private
      def post_tweet_with_media(tweet, media, options = {})
        set_twitter_client
        client.update_with_media(tweet, media, options)
      end

      def post_tweet(tweet, options = {})
        set_twitter_client
        client.update(tweet, options)
      end

      def set_twitter_client
        self.client = Twitter::REST::Client.new do |config|
          config.consumer_key        = Rails.application.secrets.twitter_consumer_key
          config.consumer_secret     = Rails.application.secrets.twitter_consumer_secret
          config.access_token        = auth_token
          config.access_token_secret = auth_secret
        end
      end
  end
end