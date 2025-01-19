module TopicPreviews
  module TopicViewSerializerExtension
    extend ActiveSupport::Concern

    included do
      attributes :user_chosen_thumbnail_url,
      :sidecar_installed
    end

    def user_chosen_thumbnail_url
      object.topic.custom_fields['user_chosen_thumbnail_url']
    end

    def sidecar_installed
      true
    end
  end
end
