class ::Topic
  attr_accessor :previewed_post
  attr_accessor :previewed_post_actions
end

module ListHelper
  class << self
    def create_topic_thumbnails(post, url)
      local = UrlHelper.is_local(url)
      image = local ? Upload.find_by(sha1: url[/[a-z0-9]{40,}/i]) : get_linked_image(post, url)
      Rails.logger.info "Creating thumbnails with: #{image}"
      thumbnails = create_thumbnails(post.topic, image, url)
      post.image_url = url
      return {id: image.id, thumbnails: thumbnails}
    end

    def get_linked_image(post, url)
      max_size = SiteSetting.max_image_size_kb.kilobytes
      image = nil

      unless Rails.env.test?
        begin
          hotlinked = FileHelper.download(
            url,
            max_file_size: max_size,
            tmp_file_name: "discourse-hotlinked",
            follow_redirect: true
          )
        rescue Discourse::InvalidParameters
        end
      end

      if hotlinked
        filename = File.basename(URI.parse(url).path)
        filename << File.extname(hotlinked.path) unless filename["."]
        image = UploadCreator.new(hotlinked, filename, origin: url).create_for(post.user_id)
      end

      image
    end

    def create_thumbnails(topic, image, original_url)
      category_height = nil
      category_width = nil

      if category = topic.category
        category_height = category.try(:custom_thumbnail_height) || category.custom_fields['topic_list_thumbnail_height']
        category_width = category.try(:custom_thumbnail_width) || category.custom_fields['topic_list_thumbnail_width']
      end

      width = category_width.present? ? category_width.to_i : SiteSetting.topic_list_thumbnail_width.to_i
      height = category_height.present? ? category_height.to_i : SiteSetting.topic_list_thumbnail_height.to_i

      # a little trick to keep aspect ratio (takes resolution from width if height specified as zero and maintains the aspect ratio)
      if height == 0 && image.try(:height) && image.try(:width)
        height = (width.to_f * (image.height.to_f/image.width.to_f)).to_i
      end

      normal = image ? thumbnail_url(image, width, height, original_url) : original_url
      retina = image ? thumbnail_url(image, width * 2, height * 2, original_url) : original_url
      thumbnails = { normal: normal, retina: retina }
      save_thumbnails(topic.id, thumbnails)
      return thumbnails
    end

    def thumbnail_url (image, w, h, original_url)
      image.create_thumbnail!(w, h) if !image.has_thumbnail?(w, h)
      image.has_thumbnail?(w, h) ? image.thumbnail(w, h).url : original_url
    end

    def save_thumbnails(id, thumbnails)
      return if !thumbnails || (thumbnails[:normal].blank? && thumbnails[:retina].blank?)
      topic = Topic.find(id)
      topic.custom_fields['thumbnails'] = thumbnails
      topic.save_custom_fields(true)
    end

    def remove_topic_thumbnails(topic)
      topic.custom_fields.delete('thumbnails')
      topic.save_custom_fields(true)
    end

    def featured_topics_enabled(category_id = nil)
      if category_id
        category = Category.find(category_id)
        category.featured_topics_enabled
      else
        SiteSetting.topic_list_featured_images
      end
    end

    def load_previewed_posts(topics, user = nil)
      # TODO: better to keep track of previewed posts' id so they can be loaded at once
      posts_map = {}
      post_actions_map = {}
      accepted_answer_post_ids = []
      qa_topic_ids = []
      normal_topic_ids = []
      previewed_post_ids = []

      topics.each do |topic|
        if post_id = topic.custom_fields["accepted_answer_post_id"]&.to_i
          accepted_answer_post_ids << post_id
        elsif ::Topic.respond_to?(:qa_enabled) && ::Topic.qa_enabled(topic)
          qa_topic_ids << topic.id
        else
          normal_topic_ids << topic.id
        end
      end

      Post.where("id IN (?)", accepted_answer_post_ids).each do |post|
        posts_map[post.topic_id] = post
        previewed_post_ids << post.id
      end

      Post.where("post_number <> 1 AND sort_order = 1 AND topic_id in (?)", qa_topic_ids).each do |post|
        posts_map[post.topic_id] = post
        previewed_post_ids << post.id
      end

      Post.where("post_number = 1 AND topic_id IN (?)", normal_topic_ids).each do |post|
        posts_map[post.topic_id] = post
        previewed_post_ids << post.id
      end

      if user
        PostAction.where("post_id IN (?) AND user_id = ?", previewed_post_ids, user.id).each do |post_action|
          (post_actions_map[post_action.post_id] ||= []) << post_action
        end
      end

      topics.each do |topic|
        topic.previewed_post = posts_map[topic.id]
        topic.previewed_post_actions = post_actions_map[topic.previewed_post.id] if topic.previewed_post
      end

      topics
    end
  end
end
