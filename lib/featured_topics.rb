require_dependency 'topic_list'
class ::TopicList
  attr_accessor :featured_topics
end

class ::Category
  def featured_topics_enabled
    if self.custom_fields['topic_list_featured_images'] != nil
      self.custom_fields['topic_list_featured_images']
    else
      SiteSetting.topic_list_featured_images &&
      SiteSetting.topic_list_featured_images_category
    end
  end
end

module PreviewsTopicQueryExtension
  def list_featured(options = {})
    create_list(:featured, { unordered: true }, featured_topics)
  end

  def create_list(filter, options = {}, topics = nil)
    list = super(filter, options, topics)
    options = options.merge(@options)

    if filter != :featured && featured_list_enabled(get_category_id(options[:category]))
      list.featured_topics = featured_topics
    end

    list
  end

  def featured_list_enabled(category_id)
    ListHelper.featured_topics_enabled(category_id)
  end

  def featured_tag_id
    @featured_tag_id ||= Tag.where(name: SiteSetting.topic_list_featured_images_tag).pluck(:id).first
  end

  def featured_topics
    tag_id = featured_tag_id

    return [] if !tag_id

    limit = SiteSetting.topic_list_featured_images_count.to_i

    result = Topic.visible
      .where('NOT topics.closed AND NOT topics.archived AND topics.deleted_at IS NULL')
      .where("topics.id in (
        SELECT topic_id FROM topic_custom_fields
        WHERE name = 'thumbnails' AND 'value' IS NOT NULL
      )")
      .joins(:tags)
      .where("tags.id = ?", tag_id)
      .order(featured_order)
      .limit(limit)

    result = @guardian.filter_allowed_categories(result)

    ListHelper.load_previewed_posts(result, @user)
  end

  def featured_order
    tag_id = featured_tag_id
    order_type = SiteSetting.topic_list_featured_order
    order = ""

    if order_type == 'tag'
      "(SELECT created_at FROM topic_tags
        WHERE topic_id = topics.id
        AND tag_id = #{tag_id})
        DESC"
    elsif order_type == 'topic'
      "topics.created_at DESC"
    end
  end

  def apply_ordering(result, options)
    if options[:tags] && options[:tags].first === SiteSetting.topic_list_featured_images_tag
      result.order(featured_order)
    else
      super(result, options)
    end
  end
end

require_dependency 'topic_query'
class ::TopicQuery
  prepend PreviewsTopicQueryExtension
end

require_dependency 'topic_view'
class ::TopicView
  def featured_topics
    @featured_topics ||= TopicQuery.new(@user).featured_topics
  end
end

module FeaturedTopicsMixin
  def self.included(klass)
    klass.attributes :featured_topics
  end

  def featured_topics
    if object.featured_topics.present?
      @featured_topics ||= begin
        object.featured_topics.map do |t|
          TopicListItemSerializer.new(t, scope: scope, root: false, featured_topics: true)
        end
      end
    else
      nil
    end
  end

  def include_featured_topics?
    featured_topics_enabled
  end
end

require_dependency 'topic_view_serializer'
class ::TopicViewSerializer
  include FeaturedTopicsMixin

  def featured_topics_enabled
    SiteSetting.topic_list_featured_images_topic &&
    ListHelper.featured_topics_enabled(object.topic.category_id)
  end
end

require_dependency 'topic_list_serializer'
class ::TopicListSerializer
  include FeaturedTopicsMixin

  def featured_topics_enabled
    featured_topics.present?
  end
end
