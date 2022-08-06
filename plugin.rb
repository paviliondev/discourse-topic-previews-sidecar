# name: discourse-topic-list-previews
# about: Sidecar Plugin to support Topic List Preview Theme Component
# version: 5.0
# authors: Robert Barrow, Angus McLeod
# url: https://github.com/paviliondev/discourse-topic-previews

gem 'color', '1.8', {require: false}
gem 'colorscore', '0.0.5', {require: true}
gem 'rmagick', '4.2.2', {require: false}
gem 'prizm', '0.0.3', {require: true}

enabled_site_setting :topic_list_previews_enabled

DiscoursePluginRegistry.serialized_current_user_fields << "tlp_user_prefs_prefer_low_res_thumbnails"

after_initialize do
  User.register_custom_field_type('tlp_user_prefs_prefer_low_res_thumbnails', :boolean)
  Topic.register_custom_field_type('user_chosen_thumbnail_url', :string)
  Topic.register_custom_field_type('dominant_colour', :json)

  register_editable_user_custom_field :tlp_user_prefs_prefer_low_res_thumbnails

  module ::TopicPreviews
    class Engine < ::Rails::Engine
      engine_name "topic_previews"
      isolate_namespace TopicPreviews
    end
  end

  load File.expand_path('../lib//thumbnail_selection_helper.rb', __FILE__)
  load File.expand_path('../lib/topic_list_previews_helper.rb', __FILE__)
  load File.expand_path('../lib/guardian_edits.rb', __FILE__)
  load File.expand_path('../lib/topic_list_edits.rb', __FILE__)
  load File.expand_path('../lib/optimized_image_edits.rb', __FILE__)
  load File.expand_path('../controllers/thumbnail_selection.rb', __FILE__)
  load File.expand_path('../lib/cooked_post_processor_edits.rb', __FILE__)
  load File.expand_path('../lib/topic_list_serializer_lib.rb', __FILE__)
  load File.expand_path('../serializers/topic_list_item_edits_mixin.rb', __FILE__)
  load File.expand_path('../serializers/topic_list_item_edits.rb', __FILE__)
  load File.expand_path('../serializers/topic_view_edits.rb', __FILE__)
  load File.expand_path('../serializers/search_topic_list_item_serializer_edits.rb', __FILE__)
  
  ::OptimizedImage.singleton_class.prepend OptimizedImmageExtension

  TopicList.preloaded_custom_fields << "accepted_answer_post_id" if TopicList.respond_to? :preloaded_custom_fields
  TopicList.preloaded_custom_fields << "dominant_colour" if TopicList.respond_to? :preloaded_custom_fields
  
  # DiscourseEvent.on(:accepted_solution) do |post|
  #   if post.image_url && SiteSetting.topic_list_previews_enabled
  #     ListHelper.create_topic_thumbnails(post, post.image_url)[:id]
  #   end
  # end

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

  DiscourseEvent.trigger(:topic_previews_ready)
end
