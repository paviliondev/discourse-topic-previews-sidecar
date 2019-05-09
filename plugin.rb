# name: discourse-topic-list-previews
# about: Allows you to add topic previews and other topic features to topic lists
# version: 0.4
# authors: Angus McLeod
# url: https://github.com/angusmcleod/discourse-topic-previews

register_asset 'stylesheets/previews_common.scss'
register_asset 'stylesheets/previews_mobile.scss'
register_asset 'javascripts/discourse/lib/masonry/masonry.js'
register_asset 'javascripts/discourse/lib/imagesloaded/imagesloaded.js'

register_svg_icon "bookmark" if respond_to?(:register_svg_icon)
register_svg_icon "heart" if respond_to?(:register_svg_icon)
register_svg_icon "id-card" if respond_to?(:register_svg_icon)

enabled_site_setting :topic_list_previews_enabled

after_initialize do
  Topic.register_custom_field_type('thumbnails', :json)
  Category.register_custom_field_type('thumbnail_width', :integer)
  Category.register_custom_field_type('thumbnail_height', :integer)
  Category.register_custom_field_type('topic_list_featured_images', :boolean)
  SiteSetting.create_thumbnails = true

  @nil_thumbs = TopicCustomField.where(name: 'thumbnails', value: nil)
  if @nil_thumbs.length
    @nil_thumbs.each do |thumb|
      hash = { normal: '', retina: '' }
      thumb.value = ::JSON.generate(hash)
      thumb.save!
    end
  end

  module ::TopicPreviews
    class Engine < ::Rails::Engine
      engine_name "topic_previews"
      isolate_namespace TopicPreviews
    end
  end

  load File.expand_path('../lib/topic_list_previews_helper.rb', __FILE__)
  load File.expand_path('../lib/guardian_edits.rb', __FILE__)
  load File.expand_path('../lib/featured_topics.rb', __FILE__)
  load File.expand_path('../lib/topic_list_edits.rb', __FILE__)
  load File.expand_path('../lib/cooked_post_processor_edits.rb', __FILE__)
  load File.expand_path('../serializers/topic_list_item_edits.rb', __FILE__)

  TopicList.preloaded_custom_fields << "accepted_answer_post_id" if TopicList.respond_to? :preloaded_custom_fields
  TopicList.preloaded_custom_fields << "thumbnails" if TopicList.respond_to? :preloaded_custom_fields

  DiscourseEvent.on(:accepted_solution) do |post|
    if post.image_url && SiteSetting.topic_list_previews_enabled
      ListHelper.create_topic_thumbnails(post, post.image_url)
    end
  end

  [
    "topic_list_tiles",
    "topic_list_excerpt",
    "topic_list_thumbnail",
    "topic_list_action",
    "topic_list_tiles_transition_time",
    "topic_list_category_column",
    "topic_list_default_thumbnail",
    "topic_list_thumbnail_width",
    "topic_list_thumbnail_height",
    "topic_list_featured_images"
  ].each do |key|
    Site.preloaded_category_custom_fields << key if Site.respond_to? :preloaded_category_custom_fields
    add_to_serializer(:basic_category, key.to_sym) { object.custom_fields[key] }
  end

  class ::TopicPreviews::ThumbnailselectionController < ::ApplicationController
    def index
      params.require(:topic)

      raise Discourse::InvalidAccess.new unless current_user

      topic_number = params[:topic].to_i

      @topic = Topic.find(topic_number)
      @user_id = @topic.user_id
      @posts = @topic.posts
      @thumbnails = []

      if current_user.id = @user_id || current_user.admin == true
        @posts.map do |post|
          @post_id = post.id
          @doc = Nokogiri::HTML( post.cooked )
          @img_srcs = @doc.css('img').map{ |i| i['src'] }
          @img_srcs.map do |image|
            if (!image.include? "emoji") && (!image.include? "avatar")
              @thumbnails << {image: image, post_id: @post_id}
            end
          end
        end
      end

      respond_to do |format|
          format.json { render json: @thumbnails}
      end
    end

    def update
      params.require(:topic_id)
      params.require(:post_id)
      params.require(:image)

      raise Discourse::InvalidAccess.new unless current_user

      @topic_id = params[:topic_id].to_i

      @topic = Topic.find(@topic_id)
      @post_id = params[:post_id].to_i
      @post = Post.find(@post_id)
      @user_id = @topic.user_id
      @thumbnail = params[:image].to_s

      if current_user.id = @user_id || current_user.admin == true
          @topic.update_column(:image_url, @thumbnail) # topic
          return if SiteSetting.topic_list_hotlink_thumbnails ||
                    !SiteSetting.topic_list_previews_enabled

          if upload_id = ListHelper.create_topic_thumbnails(@post, @thumbnail)

            ## ensure there is a post_upload record so the upload is not removed in the cleanup
            unless PostUpload.where(post_id: @post.id).exists?
              PostUpload.create(post_id: @post.id, upload_id: upload_id)
            end
          end
          @topic.save!
      end
    end
  end

  Discourse::Application.routes.append do
    mount ::TopicPreviews::Engine, at: '/'
  end

  TopicPreviews::Engine.routes.draw do
    get '/thumbnailselection' => 'thumbnailselection#index'
    put '/thumbnailselection' => 'thumbnailselection#update'
  end



  DiscourseEvent.trigger(:topic_previews_ready)
end
