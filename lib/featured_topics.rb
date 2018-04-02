require_dependency 'topic_list'
class ::TopicList
  attr_accessor :featured_topics
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
    if !category_id || SiteSetting.topic_list_featured_images_category
      SiteSetting.topic_list_featured_images
    else
      category = Category.find(category_id)
      category.custom_fields['topic_list_featured_images']
    end
  end

  def featured_topics
    tag = SiteSetting.topic_list_featured_images_tag

    return [] if !tag

    tag_id = Tag.where(name: tag).pluck(:id).first
    limit = SiteSetting.topic_list_featured_images_count

    result = Topic.visible
      .where('NOT topics.closed AND NOT topics.archived AND topics.deleted_at IS NULL')
      .joins(:tags)
      .where("tags.id = ?", tag_id)

    @guardian.filter_allowed_categories(result)

    result.order("(
      SELECT created_at FROM topic_tags
      WHERE topic_id = topics.id
      AND tag_id = #{tag_id})
      DESC
    ")
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
    if !object.topic.category || SiteSetting.topic_list_featured_images_category
      SiteSetting.topic_list_featured_images
    else
      object.topic.category.custom_fields['topic_list_featured_images']
    end
  end
end

require_dependency 'topic_list_serializer'
class ::TopicListSerializer
  include FeaturedTopicsMixin

  def featured_topics_enabled
    featured_topics.present?
  end
end
