# name: discourse-topic-list-previews
# about: Allows you to add topic previews and other topic features to topic lists
# version: 4.4.0
# authors: Robert Barrow, Angus McLeod
# url: https://github.com/paviliondev/discourse-topic-previews

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
  Topic.register_custom_field_type('user_chosen_thumbnail_url', :string)
  Category.register_custom_field_type('thumbnail_width', :integer)
  Category.register_custom_field_type('thumbnail_height', :integer)
  Category.register_custom_field_type('topic_list_featured_images', :boolean)

  register_editable_user_custom_field :tlp_user_prefs_prefer_low_res_thumbnails

  register_topic_thumbnail_size [50, 50]
  register_topic_thumbnail_size [100, 100]
  register_topic_thumbnail_size [200, 200]
  register_topic_thumbnail_size [400, 400]
  register_topic_thumbnail_size [800, 800]

  module ::TopicPreviews
    class Engine < ::Rails::Engine
      engine_name "topic_previews"
      isolate_namespace TopicPreviews
    end
  end

  Post.register_custom_field_type('thumbnail_upload_id', :integer)

  load File.expand_path('../lib//thumbnail_selection_helper.rb', __FILE__)
  load File.expand_path('../lib/topic_list_previews_helper.rb', __FILE__)
  load File.expand_path('../lib/guardian_edits.rb', __FILE__)
  load File.expand_path('../lib/featured_topics.rb', __FILE__)
  load File.expand_path('../lib/topic_list_edits.rb', __FILE__)
  load File.expand_path('../controllers/thumbnail_selection.rb', __FILE__)
  load File.expand_path('../lib/cooked_post_processor_edits.rb', __FILE__)
  load File.expand_path('../serializers/topic_list_item_edits_mixin.rb', __FILE__)
  load File.expand_path('../serializers/topic_list_item_edits.rb', __FILE__)
  load File.expand_path('../serializers/topic_view_edits.rb', __FILE__)
  
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

  TopicList.preloaded_custom_fields << "user_chosen_thumbnail_url" if TopicList.respond_to? :preloaded_custom_fields
  PostRevisor.track_topic_field("user_chosen_thumbnail_url".to_sym) do |tc, tf|
    tc.record_change("user_chosen_thumbnail_url", tc.topic.custom_fields["user_thumbnail_choice"], tf)
    tc.topic.custom_fields["user_chosen_thumbnail_url"] = tf
  end
  PostRevisor.track_topic_field("image_upload_id".to_sym) do |tc, tf|
    tc.record_change("image_upload_id", tc.topic.image_upload_id, tf)
    tc.topic.image_upload_id = tf
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
