require_dependency 'cooked_post_processor'
CookedPostProcessor.class_eval do
  def extract_images_for_post
    # all images with a src attribute
    @doc.css("img[src]") -
    # minus emojis
    @doc.css("img.emoji") -
    # minus images inside quotes
    @doc.css(".quote img") -
    # minus onebox site icons
    @doc.css("img.site-icon") -
    # minus onebox avatars
    @doc.css("img.onebox-avatar") #-
    # minus small onebox images (large images are .aspect-image-full-size)
   # @doc.css(".onebox .aspect-image img")
  end
  
  # def extract_post_image
  #   (extract_images_for_post -
  #   @doc.css("img.thumbnail") -
  #   @doc.css("img.site-icon") -
  #   @doc.css("img.avatar"))
  #     .select { |img| validate_image_for_previews(img) }
  #     .first
  # end

  # def determine_image_size(img)
  #   get_size_from_attributes(img) ||
  #   get_size_from_image_sizes(img["src"], @opts[:image_sizes]) ||
  #   get_size(img["src"])
  # end

  # def validate_image_for_previews(img)
  #   w, h = determine_image_size(img)

  #   return false if w.blank? || h.blank?

  #   w.to_i >= SiteSetting.topic_list_previewable_image_width_min.to_i &&
  #   h.to_i >= SiteSetting.topic_list_previewable_image_height_min.to_i
  # end

  def update_post_image
    
    unless @post.is_first_post? && @post.topic.custom_fields["user_chosen_thumbnail_url"]

      upload = nil
      mypixels = nil
      eligible_image_fragments = extract_images_for_post
    
      # Loop through those fragments until we find one with an upload record
      @post.each_upload_url(fragments: eligible_image_fragments) do |src, path, sha1|
        upload = Upload.find_by(sha1: sha1)
        break if upload
      end
    
      if upload.present?
        @post.update_column(:image_upload_id, upload.id) # post
        if @post.is_first_post? # topic
          @post.topic.update_column(:image_upload_id, upload.id)
          extra_sizes = ThemeModifierHelper.new(theme_ids: Theme.user_selectable.pluck(:id)).topic_thumbnail_sizes
          @post.topic.generate_thumbnails!(extra_sizes: extra_sizes)
        end
      else
        @post.update_column(:image_upload_id, nil) if @post.image_upload_id
        @post.topic.update_column(:image_upload_id, nil) if @post.topic.image_upload_id && @post.is_first_post?
        nil
      end
      mypixels = Prizm::Extractor.new("public" + Upload.find_by(id: upload.id).url).get_colors(5).first
    else
      extra_sizes = ThemeModifierHelper.new(theme_ids: Theme.user_selectable.pluck(:id)).topic_thumbnail_sizes
      @post.topic.generate_thumbnails!(extra_sizes: extra_sizes)
      mypixels = Prizm::Extractor.new("public" + Upload.find_by(id: @post.topic.image_upload_id).url).get_colors(5).first
    end

    if mypixels
      red =  mypixels.red/256
      green = mypixels.green/256
      blue = mypixels.blue/256

      topic = Topic.find(@post.topic.id)
      topic.custom_fields['dominant_colour'] = {red: red, green: green, blue: blue}
      topic.save_custom_fields(true)
    end
  end
end
