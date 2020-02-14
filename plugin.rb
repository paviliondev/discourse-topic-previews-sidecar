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
register_svg_icon "images" if respond_to?(:register_svg_icon)

enabled_site_setting :topic_list_previews_enabled

DiscoursePluginRegistry.serialized_current_user_fields << "tlp_user_prefs_prefer_low_res_thumbnails"

after_initialize do
  User.register_custom_field_type('tlp_user_prefs_prefer_low_res_thumbnails', :boolean)
  Topic.register_custom_field_type('thumbnails', :json)
  Topic.register_custom_field_type('thumbnail_from_post', :integer)
  Category.register_custom_field_type('thumbnail_width', :integer)
  Category.register_custom_field_type('thumbnail_height', :integer)
  Category.register_custom_field_type('topic_list_featured_images', :boolean)

  register_editable_user_custom_field :tlp_user_prefs_prefer_low_res_thumbnails

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

  Post.register_custom_field_type('thumbnail_upload_id', :integer)

  load File.expand_path('../lib/post_edits.rb', __FILE__)
  load File.expand_path('../lib/topic_list_previews_helper.rb', __FILE__)
  load File.expand_path('../lib/guardian_edits.rb', __FILE__)
  load File.expand_path('../lib/featured_topics.rb', __FILE__)
  load File.expand_path('../lib/topic_list_edits.rb', __FILE__)
  load File.expand_path('../lib/cooked_post_processor_edits.rb', __FILE__)
  load File.expand_path('../serializers/topic_list_item_edits_mixin.rb', __FILE__)
  load File.expand_path('../serializers/topic_list_item_edits.rb', __FILE__)
  
  TopicList.preloaded_custom_fields << "accepted_answer_post_id" if TopicList.respond_to? :preloaded_custom_fields
  TopicList.preloaded_custom_fields << "thumbnails" if TopicList.respond_to? :preloaded_custom_fields

  DiscourseEvent.on(:accepted_solution) do |post|
    if post.image_url && SiteSetting.topic_list_previews_enabled
      ListHelper.create_topic_thumbnails(post, post.image_url)[:id]
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
    add_to_serializer(:basic_category, key.to_sym, false) { object.custom_fields[key] }
  end

  PostRevisor.class_eval do
    track_topic_field(:image_url) do |tc, image_url|
      tc.record_change('image_url', tc.topic.image_url, image_url)
      tc.topic.image_url = image_url

      topic_id = tc.topic.id
      thumbnail_post = nil
      thumbnail_post_id  = nil
      topic = Topic.find(topic_id)
      @posts = topic.posts

      @posts.each do |post|
          post_id = post.id
          doc = Nokogiri::HTML( post.cooked )
          @img_srcs = doc.css('img').map{ |i| i['src'] }
          @img_srcs << post.image_url if (!post.image_url.blank? && (!@img_srcs.include? post.image_url))
          @img_srcs.each do |image|
            if image == image_url
              thumbnail_post = post
              thumbnail_post_id = post_id
            end
          end
          break if thumbnail_post_id != nil
      end

      tc.record_change('thumbnail_from_post', tc.topic.custom_fields['thumbnail_from_post'], thumbnail_post_id)
      tc.topic.custom_fields['thumbnail_from_post'] = thumbnail_post_id

      unless SiteSetting.topic_list_hotlink_thumbnails ||
                !SiteSetting.topic_list_previews_enabled
        if !thumbnail_post_id.nil?
          thumbnails = ListHelper.create_topic_thumbnails(thumbnail_post, image_url)
          if thumbnails[:id]
            tc.record_change('thumbnails', tc.topic.custom_fields['thumbnails'], thumbnails[:thumbnails])
            tc.topic.custom_fields['thumbnails'] = thumbnails[:thumbnails]
            ## ensure there is a post_upload record so the upload is not removed in the cleanup
            unless PostUpload.where(post_id: thumbnail_post_id).exists?
              PostUpload.create(post_id: thumbnail_post_id, upload_id: thumbnails[:id])
            end
          end
        end
      end
    end
  end

  Discourse::Application.routes.append do
    mount ::TopicPreviews::Engine, at: '/topic-previews'
  end

  TopicPreviews::Engine.routes.draw do
    get '/thumbnail-selection' => 'thumbnailselection#index'
  end

  load File.expand_path('../controllers/thumbnail_selection.rb', __FILE__)

  DiscourseEvent.trigger(:topic_previews_ready)
end
