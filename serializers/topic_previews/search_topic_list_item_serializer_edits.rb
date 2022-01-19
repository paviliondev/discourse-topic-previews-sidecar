
module SearchTopicListItemSerializerAddon
  def include_thumbnails?
    true
  end
end

class SearchTopicListItemSerializer
  if SiteSetting.topic_list_search_previews_enabled
    prepend SearchTopicListItemSerializerAddon
  end
end
