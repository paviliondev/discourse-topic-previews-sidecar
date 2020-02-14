require 'topic_list_item_serializer'
class ::TopicListItemSerializer
  include TopicListItemEditsMixin

  attributes :thumbnails,
             :topic_post_id,
             :topic_post_liked,
             :topic_post_like_count,
             :topic_post_can_like,
             :topic_post_can_unlike,
             :topic_post_bookmarked,
             :topic_post_is_current_users,
             :topic_post_number,
             :topic_post_user


  alias :include_topic_post_can_unlike? :include_topic_post_id?
end

class ::SuggestedTopicSerializer
  include TopicListItemEditsMixin

  attributes :thumbnails,
             :topic_post_id,
             :topic_post_liked,
             :topic_post_like_count,
             :topic_post_can_like,
             :topic_post_can_unlike,
             :topic_post_bookmarked,
             :topic_post_is_current_users,
             :topic_post_number,
             :topic_post_user
end