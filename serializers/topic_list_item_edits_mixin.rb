# frozen_string_literal: true

module TopicListItemEditsMixin
  def excerpt
    if object.previewed_post
      doc = Nokogiri::HTML::fragment(object.previewed_post.cooked)
      doc.search('.//img').remove
      PrettyText.excerpt(doc.to_html, SiteSetting.topic_list_excerpt_length, keep_emoji_images: true)
    else
      object.excerpt
    end
  end

  def include_excerpt?
    object.excerpt.present? && SiteSetting.topic_list_previews_enabled   && !(object.archetype == Archetype.private_message)
  end

  def thumbnails
    return unless object.archetype == Archetype.default

    if SiteSetting.topic_list_hotlink_thumbnails || @options[:featured_topics] && SiteSetting.topic_list_featured_images_full_res
      original_images
    else
      get_thumbnails || get_thumbnails_from_image_url
    end
  end

  def include_thumbnails?
    return unless SiteSetting.topic_list_previews_enabled && thumbnails.present?
    thumbnails['normal'].present? && is_thumbnail?(thumbnails['normal'])
  end

  def is_thumbnail?(path)
    path.is_a?(String) &&
    path != 'false' &&
    path != 'null' &&
    path != 'nil'
  end

  def get_thumbnails
    thumbs = object.custom_fields['thumbnails']
    if thumbs.is_a?(String)
      thumbs = ::JSON.parse(thumbs)
    end
    if thumbs.is_a?(Array)
      thumbs = thumbs[0]
    end
    thumbs.is_a?(Hash) ? thumbs : false
  end

  def get_thumbnails_from_image_url
    image = Upload.get_from_url(object.image_url) rescue false
    return ListHelper.create_thumbnails(object, image, object.image_url)
  end

  def original_images
    { 'normal' => object.image_url, 'retina' => object.image_url }
  end

  def include_topic_post_id?
    object.previewed_post.present? && SiteSetting.topic_list_previews_enabled
  end

  def topic_post_id
    object.previewed_post&.id
  end

  def topic_post_number
    object.previewed_post&.post_number
  end

  def topic_post_user
    if object.previewed_post
      @topic_post_user ||= BasicUserSerializer.new(object.previewed_post.user, scope: scope, root: false).as_json
    else
      nil
    end
  end

  def include_topic_post_user?
    @options[:featured_topics] && topic_post_user.present?
  end

  def topic_post_actions
    object.previewed_post_actions || []
  end

  def topic_like_action
    topic_post_actions.select { |a| a.post_action_type_id == PostActionType.types[:like] }
  end

  def topic_post_bookmarked
    !!topic_post_actions.any? { |a| a.post_action_type_id == PostActionType.types[:bookmark] }
  end
  alias :include_topic_post_bookmarked? :include_topic_post_id?

  def topic_post_liked
    topic_like_action.any?
  end
  alias :include_topic_post_liked? :include_topic_post_id?

  def topic_post_like_count
    object.previewed_post&.like_count
  end

  def include_topic_post_like_count?
    object.previewed_post&.id && topic_post_like_count > 0 && SiteSetting.topic_list_previews_enabled
  end

  def topic_post_can_like
    return false if !scope.current_user || topic_post_is_current_users
    scope.previewed_post_can_act?(object.previewed_post, object, PostActionType.types[:like], taken_actions: topic_post_actions)
  end
  alias :include_topic_post_can_like? :include_topic_post_id?

  def topic_post_is_current_users
    return scope.current_user && (object.previewed_post&.user_id == scope.current_user.id)
  end
  alias :include_topic_post_is_current_users? :include_topic_post_id?

  def topic_post_can_unlike
    return false if !scope.current_user
    action = topic_like_action[0]
    !!(action && (action.user_id == scope.current_user.id) && (action.created_at > SiteSetting.post_undo_action_window_mins.minutes.ago))
  end
end