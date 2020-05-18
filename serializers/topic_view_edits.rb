require 'topic_view_serializer'
class ::TopicViewSerializer

  attributes :user_chosen_thumbnail_url

  def user_chosen_thumbnail_url
    object.topic.custom_fields['user_chosen_thumbnail_url']
  end
end
