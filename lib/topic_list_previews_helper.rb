module ListHelper
  class << self
    def create_topic_thumbnails(post, url)
      local = UrlHelper.is_local(url)
      image = local ? Upload.find_by(sha1: url[/[a-z0-9]{40,}/i]) : get_linked_image(post, url)
      Rails.logger.info "Creating thumbnails with: #{image}"
      create_thumbnails(post.topic, image, url)
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
      category_height = topic.category ? topic.category.custom_fields['topic_list_thumbnail_height'] : nil
      category_width = topic.category ? topic.category.custom_fields['topic_list_thumbnail_width'] : nil
      width = category_width.present? ? category_width.to_i : SiteSetting.topic_list_thumbnail_width.to_i
      height = category_height.present? ? category_height.to_i : SiteSetting.topic_list_thumbnail_height.to_i
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
  end
end
