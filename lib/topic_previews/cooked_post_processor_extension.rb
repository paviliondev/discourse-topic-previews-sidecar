require_dependency 'cooked_post_processor'

module TopicPreviews
  module CookedPostProcessorExtension
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
        # mypixels = nil
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
            @post.topic.generate_thumbnails!(extra_sizes: get_extra_sizes)
          end
          # if SiteSetting.topic_list_enable_thumbnail_colour_determination
          #   mypixels = get_dominant_colour(@post.topic.image_upload_id)
          # end
        else
          @post.update_column(:image_upload_id, nil) if @post.image_upload_id
          @post.topic.update_column(:image_upload_id, nil) if @post.topic.image_upload_id && @post.is_first_post?
          nil
        end
      else
        @post.topic.generate_thumbnails!(extra_sizes: get_extra_sizes)
        # if SiteSetting.topic_list_enable_thumbnail_colour_determination
        #   mypixels = get_dominant_colour(@post.topic.image_upload_id)
        # end
      end

      # if mypixels
      #   red =  mypixels.red/256
      #   green = mypixels.green/256
      #   blue = mypixels.blue/256

      #   topic = Topic.find(@post.topic.id)
      #   topic.custom_fields['dominant_colour'] = {red: red, green: green, blue: blue}
      #   topic.save_custom_fields(true)
      # end
    end

    # def get_dominant_colour(upload_id)
    #   Prizm::Extractor.new("public" + OptimizedImage.where(upload_id: upload_id).order('width DESC').first.url).get_colors(5, false).first
    # end

    def get_extra_sizes
      ThemeModifierHelper.new(theme_ids: Theme.all.pluck(:id)).topic_thumbnail_sizes
    end
  end
end
