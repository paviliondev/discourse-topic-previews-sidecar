class TopicViewSerializer

  attributes :user_chosen_thumbnail_url,
             :sidecar_installed

  def user_chosen_thumbnail_url
    object.topic.custom_fields['user_chosen_thumbnail_url']
  end

  def sidecar_installed
    true
  end
end
