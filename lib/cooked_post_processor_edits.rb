require_dependency 'cooked_post_processor'
CookedPostProcessor.class_eval do
  def extract_post_image
    (extract_images_for_post -
    @doc.css("img.thumbnail") -
    @doc.css("img.site-icon") -
    @doc.css("img.avatar"))
      .select { |img| validate_image_for_previews(img) }
      .first
  end

  def determine_image_size(img)
    get_size_from_attributes(img) ||
    get_size_from_image_sizes(img["src"], @opts[:image_sizes]) ||
    get_size(img["src"])
  end

  def validate_image_for_previews(img)
    w, h = determine_image_size(img)

    return false if w.blank? || h.blank?

    w.to_i >= SiteSetting.topic_list_previewable_image_width_min.to_i &&
    h.to_i >= SiteSetting.topic_list_previewable_image_height_min.to_i
  end

  def update_post_image
    return if !@post.topic.image_url.blank? && !@post.topic.custom_fields['thumbnail_from_post'].blank?  
    img = extract_post_image
    
    if @has_oneboxes
      cooked = PrettyText.cook(@post.raw)

      if img
        ## We need something more specific to identify the image with
        img_id = img
        src = img.attribute("src").to_s
        img_id = src.split('/').last.split('.').first if src
      end

      prior_oneboxes = []
      Oneboxer.each_onebox_link(cooked) do |url, element|
        if !img || (img && cooked.index(element).to_i < cooked.index(img_id).to_i)
          html = Nokogiri::HTML::fragment(Oneboxer.cached_preview(url))
          prior_oneboxes = html.css('img')
        end
      end

      if prior_oneboxes.any?
        prior_oneboxes = prior_oneboxes.reject do |html|
          class_str = html.attribute('class').to_s
          class_str.include?('site-icon') || class_str.include?('avatar')
        end

        if prior_oneboxes.any? && validate_image_for_previews(prior_oneboxes.first)
          img = prior_oneboxes.first
        end
      end
    end
    
    if img.blank?
      @post.update_column(:image_url, nil)
      if @post.is_first_post? && (@post.topic.custom_fields['thumbnail_from_post'].blank? || @post.topic.custom_fields['thumbnail_from_post'] == @post.id)
        @post.topic.update_column(:image_url, nil)
        ListHelper.remove_topic_thumbnails(@post.topic)
      end
    elsif img["src"].present?
      url = img["src"][0...255]
      @post.update_column(:image_url, url) # post

      if @post.is_first_post? && @post.topic.custom_fields['thumbnail_from_post'].blank?
        @post.topic.update_column(:image_url, url) # topic
        return if SiteSetting.topic_list_hotlink_thumbnails ||
                  !SiteSetting.topic_list_previews_enabled

        if upload_id = ListHelper.create_topic_thumbnails(@post, url)[:id]
          # make a record of the upload id so it can be included in the PostUpload update later in the process
          @post.custom_fields['thumbnail_upload_id'] = upload_id
        end
      end
    end
  end
end
