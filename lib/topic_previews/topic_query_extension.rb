module TopicPreviews
  module TopicQueryExtension
    # def list_featured(options = {})
    #   create_list(:featured, { unordered: true, featured_list: true }, featured_topics)
    # end

    # def create_list(filter, options = {}, topics = nil)
    #   list = super(filter, options, topics)
    #   options = options.merge(@options)

    #   if filter != :featured && featured_list_enabled(get_category_id(options[:category]))
    #     list.featured_topics = featured_topics
    #   end

    #   list
    # end

    # def featured_list_enabled(category_id)
    #   Category.featured_topics_enabled(category_id)
    # end

    # def featured_tags
    #   SiteSetting.topic_list_featured_images_tag.split('|')
    # end

    # def featured_tag_ids
    #   Tag.where(name: featured_tags).pluck(:id)
    # end

    # def featured_topics
    #   tag_ids = featured_tag_ids

    #   return [] if tag_ids.blank?

    #   limit = SiteSetting.topic_list_featured_images_count.to_i

    #   result = Topic.visible
    #     .where('NOT topics.closed AND NOT topics.archived AND topics.deleted_at IS NULL')
    #     .where('topics.image_upload_id IS NOT NULL')
    #     .joins(:tags)
    #     .where("tags.id IN (?)", tag_ids)
    #     .order(featured_order)
    #     .limit(limit)

    #   result = @guardian.filter_allowed_categories(result)

    #   ListHelper.load_previewed_posts(result, @user)
    # end

    # def featured_order
    #   tag_ids = featured_tag_ids
    #   order_type = SiteSetting.topic_list_featured_order
    #   order = ""

    #   if order_type == 'tag' && tag_ids.any?
    #     "(SELECT created_at FROM topic_tags
    #       WHERE topic_id = topics.id
    #       AND tag_id IN (#{tag_ids.join(', ')})
    #       LIMIT 1)
    #       DESC"
    #   elsif order_type == 'topic'
    #     "topics.created_at DESC"
    #   end
    # end

    # def apply_ordering(result, options)
    #   if options[:featured_list] && options[:tags] && (options[:tags] && featured_tags).any?
    #     result.order(featured_order)
    #   else
    #     super(result, options)
    #   end
    # end
  end
end