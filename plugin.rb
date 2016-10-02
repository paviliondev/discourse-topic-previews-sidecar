# name: discourse-topic-previews
# about: A Discourse plugin that gives you a topic preview image in the topic list
# version: 0.2
# authors: Angus McLeod

register_asset 'stylesheets/previews_common.scss'
register_asset 'stylesheets/previews_mobile.scss'

after_initialize do

  Category.register_custom_field_type('list_thumbnails', :boolean)
  Category.register_custom_field_type('list_excerpts', :boolean)
  Category.register_custom_field_type('list_actions', :boolean)
  Category.register_custom_field_type('list_category_badge_move', :boolean)
  Topic.register_custom_field_type('thumbnails', :json)
  Topic.register_custom_field_type('first_post_id', :integer)
  Topic.register_custom_field_type('topic_post_can_like', :boolean)

  @thumbs = TopicCustomField.where( name: 'thumbnails' )
  if @thumbs.length
    @thumbs.each do |thumb|
      if thumb.value.is_a?(Hash)
        thumb.value = thumb.value.to_json
        thumb.save!
      elsif thumb.value.is_a?(String)
        thumb.value = ::JSON.parse(thumb.value.gsub('=>', ':').gsub('nil', 'null')).to_json
        thumb.save!
      elsif thumb.value.is_a?(Array)
        thumb.value = thumb.value[0]
        thumb.save!
      end
    end
  end

  module ListHelper
    class << self
      def create_thumbnails(post, image, original_url)
        width = SiteSetting.topic_list_thumbnail_width
        height = SiteSetting.topic_list_thumbnail_height
        normal = image ? thumbnail_url(image, width, height) : original_url
        retina = image ? thumbnail_url(image, width*2, height*2) : original_url
        thumbnails = { normal: normal, retina: retina }
        Rails.logger.info "Saving thumbnails: #{thumbnails}"
        topic = Topic.find(post.topic.id)
        save_topic_fields(topic, post, thumbnails)
        return thumbnails
      end

      def thumbnail_url (image, w, h)
        image.create_thumbnail!(w, h) if !image.has_thumbnail?(w, h)
        image.thumbnail(w, h).url
      end

      def save_topic_fields(topic, post, thumbnails)
       topic.custom_fields['first_post_id'] = post.id
       topic.custom_fields['thumbnails'] = thumbnails
       topic.excerpt = generate_excerpt(post)
       topic.save_custom_fields
      end

      def save_first_post_id(post_id, topic_id)
        topic = Topic.find(topic_id)
        topic.custom_fields['first_post_id'] = post_id
        topic.save_custom_fields
      end

      def generate_excerpt(post, topic_id)
        post = post || Post.find_by(topic_id: topic_id, post_number: 1)
        cooked = post.cooked
        excerpt = PrettyText.excerpt(cooked[0], SiteSetting.topic_list_excerpt_length, keep_emoji_images: true)
        excerpt.gsub!(/(\[#{I18n.t 'excerpt_image'}\])/, "") if excerpt
        excerpt
      end

      def save_topic_post_can_like(topic, post, post_actions)
        guardian = Guardian.new(post.user)
        can_like = guardian.post_can_act?(post, PostActionType.types[:like], taken_actions: post_actions)
        topic.custom_fields['topic_post_can_like'] = can_like
        topic.save_custom_fields
        can_like
      end
    end
  end

  DiscourseEvent.on(:post_created) do |post, opts, user|
    if post.is_first_post?
      ListHelper.save_first_post_id(post.topic_id, post.id)
    end
  end

  require 'cooked_post_processor'
  class ::CookedPostProcessor

    def get_linked_image(url)
      max_size = SiteSetting.max_image_size_kb.kilobytes
      file = FileHelper.download(url, max_size, "discourse", true) rescue nil
      Rails.logger.info "Downloaded linked image: #{file}"
      image = file ? Upload.create_for(@post.user_id, file, file.path.split('/')[-1], File.size(file.path)) : nil
      image
    end

    def create_topic_thumbnails(url)
      local = UrlHelper.is_local(url)
      image = local ? Upload.find_by(sha1: url[/[a-z0-9]{40,}/i]) : get_linked_image(url)
      Rails.logger.info "Creating thumbnails with: #{image}"
      ListHelper.create_thumbnails(@post, image, url)
    end

    def update_topic_image
      if @post.is_first_post?
        img = extract_images_for_topic.first
        Rails.logger.info "Updating topic image: #{img}"
        return if !img["src"]
        url = img["src"][0...255]
        @post.topic.update_column(:image_url, url)
        create_topic_thumbnails(url)
      end
    end
  end

  require 'topic_list_item_serializer'
  class ::TopicListItemSerializer
    attributes :thumbnails,
               :topic_post_id,
               :topic_post_liked,
               :topic_post_like_count,
               :topic_post_can_like,
               :topic_post_can_unlike,
               :topic_post_bookmarked,
               :topic_post_is_current_users

    def first_post_id
      if object.custom_fields["first_post_id"]
        return object.custom_fields["first_post_id"]
      else
        p "first_post_id not saved"
        p object.id
        post = Post.find_by(topic_id: object.id, post_number: 1)
        ListHelper.save_first_post_id(post.id, post.topic_id)
        post.id
      end
    end

    def topic_post_id
      accepted_id = object.custom_fields["accepted_answer_post_id"].to_i
      accepted_id > 0 ? accepted_id : first_post_id
    end
    alias :include_topic_post_id? :first_post_id

    def topic_post
      Post.find(topic_post_id)
    end

    def topic_post_actions
      return [] if !scope.current_user
      PostAction.where(post_id: topic_post_id, user_id: scope.current_user.id)
    end

    def topic_post_can_like
      return false if !scope.current_user || topic_post_is_current_users
      can_like = object.custom_fields['topic_post_can_like']
      return can_like if can_like
      topic = Topic.find(topic_post.topic_id)
      ListHelper.save_topic_post_can_like(topic, topic_post, topic_post_actions)
    end
    alias :include_topic_post_can_like? :first_post_id

    def topic_like_action
      topic_post_actions.select {|a| a.post_action_type_id == PostActionType.types[:like]}
    end

    def topic_post_bookmarked
      !!topic_post_actions.any?{|a| a.post_action_type_id == PostActionType.types[:bookmark]}
    end
    alias :include_topic_post_bookmarked? :first_post_id

    def topic_post_liked
      topic_like_action.any?
    end
    alias :include_topic_post_liked? :first_post_id

    def topic_post_like_count
      topic_like_action.length
    end
    alias :include_topic_post_like_count? :first_post_id

    def include_topic_post_like_count?
      first_post_id && topic_post_like_count > 0
    end

    def topic_post_is_current_users
      return scope.current_user && (topic_post.user_id == scope.current_user.id)
    end
    alias :include_topic_post_is_current_users? :first_post_id

    def topic_post_can_unlike
      return false if !scope.current_user || topic_like_action.empty?
      action = topic_like_action[0]
      user_action = action.user_id == scope.current_user.id
      not_rate_limited = action.created_at > SiteSetting.post_undo_action_window_mins.minutes.ago
      action && user_action && not_rate_limited
    end
    alias :include_topic_post_can_unlike? :first_post_id

    def excerpt
      object.excerpt || ListHelper.generate_excerpt(object.id)
    end

    def include_excerpt?
      object.excerpt.present?
    end

    def thumbnails
      object.archetype == Archetype.default ? get_thumbnails : ''
    end

    def include_thumbnails?
      thumbnails.present?
    end

    def get_thumbnails
      thumbnails = object.custom_fields['thumbnails']
      thumbnails.is_a?(String) ? ::JSON.parse(thumbnails) : thumbnails
    end
  end

  TopicList.preloaded_custom_fields << "topic_post_can_like" if TopicList.respond_to? :preloaded_custom_fields
  TopicList.preloaded_custom_fields << "first_post_id" if TopicList.respond_to? :preloaded_custom_fields
  TopicList.preloaded_custom_fields << "accepted_answer_post_id" if TopicList.respond_to? :preloaded_custom_fields
  TopicList.preloaded_custom_fields << "thumbnails" if TopicList.respond_to? :preloaded_custom_fields

  add_to_serializer(:basic_category, :list_excerpts) {object.custom_fields["list_excerpts"]}
  add_to_serializer(:basic_category, :list_thumbnails) {object.custom_fields["list_thumbnails"]}
  add_to_serializer(:basic_category, :list_actions) {object.custom_fields["list_actions"]}
  add_to_serializer(:basic_category, :list_category_badge_move) {object.custom_fields["list_category_badge_move"]}
  add_to_serializer(:basic_category, :list_default_thumbnail) {object.custom_fields["list_default_thumbnail"]}
end
