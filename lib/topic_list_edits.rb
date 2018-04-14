module TopicListAddon
  def load_topics
    @topics = super

    if SiteSetting.topic_list_previews_enabled
      @topics = ListHelper.load_previewed_posts(@topics, @current_user)
    end

    @topics
  end
end

class ::TopicList
  prepend TopicListAddon
end
