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
        if SiteSetting.topic_list_enable_thumbnail_colour_determination
          mypixels = Prizm::Extractor.new("public" + Upload.find_by(id: upload.id).url).get_colors(10).first
        end
      else
        @post.update_column(:image_upload_id, nil) if @post.image_upload_id
        @post.topic.update_column(:image_upload_id, nil) if @post.topic.image_upload_id && @post.is_first_post?
        nil
      end
    else
      extra_sizes = ThemeModifierHelper.new(theme_ids: Theme.user_selectable.pluck(:id)).topic_thumbnail_sizes
      @post.topic.generate_thumbnails!(extra_sizes: extra_sizes)
      if SiteSetting.topic_list_enable_thumbnail_colour_determination
        mypixels = Prizm::Extractor.new("public" + Upload.find_by(id: @post.topic.image_upload_id).url).get_colors(10).first
      end
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
