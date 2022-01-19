# name: discourse-topic-list-previews
# about: Allows you to add topic previews and other topic features to topic lists
# version: 4.3.1
# authors: Robert Barrow, Angus McLeod
# url: https://github.com/paviliondev/discourse-topic-previews

gem 'color', '1.8', {require: false}
gem 'colorscore', '0.0.5', {require: true}
gem 'rmagick', '4.2.3', {require: false}
gem 'prizm', '0.0.3', {require: true}
# gem 'oily_png', '1.1.0', {require: false}
# gem 'climate_control', '0.2.0', {require: false}
# gem 'terrapin', '0.6.0', {require: false}
# gem 'cocaine', '0.6.0', {require: false}
# gem 'miro', '0.4.0', {require: true}
register_asset 'stylesheets/admin/admin.scss', :desktop

enabled_site_setting :topic_list_previews_enabled

DiscoursePluginRegistry.serialized_current_user_fields << "tlp_user_prefs_prefer_low_res_thumbnails"

after_initialize do
  User.register_custom_field_type('tlp_user_prefs_prefer_low_res_thumbnails', :boolean)
  Topic.register_custom_field_type('user_chosen_thumbnail_url', :string)
  Topic.register_custom_field_type('dominant_colour', :json)

  register_editable_user_custom_field :tlp_user_prefs_prefer_low_res_thumbnails

  %w[
    ../lib/topic_previews/engine.rb
    ../config/routes.rb
    ../controllers/topic_previews/admin/admin.rb
    ../controllers/topic_previews/admin/subscription.rb
    ../controllers/topic_previews/admin/notice.rb
    ../controllers/topic_previews/thumbnail_selection.rb
    ../jobs/scheduled/topic_previews/update_subscription.rb
    ../jobs/scheduled/topic_previews/update_notices.rb
    ../lib/topic_previews/notice.rb
    ../lib/topic_previews/notice/connection_error.rb
    ../lib/topic_previews/subscription.rb
    ../lib/topic_previews/subscription/subscription.rb
    ../lib/topic_previews/subscription/authentication.rb
    ../lib//thumbnail_selection_helper.rb
    ../lib/topic_list_previews_helper.rb
    ../lib/guardian_edits.rb
    ../lib/topic_list_edits.rb
    ../lib/cooked_post_processor_edits.rb
    ../lib/topic_list_serializer_lib.rb
    ../serializers/topic_previews/subscription/authentication_serializer.rb
    ../serializers/topic_previews/subscription/subscription_serializer.rb
    ../serializers/topic_previews/subscription_serializer.rb
    ../serializers/topic_previews/notice_serializer.rb
    ../serializers/topic_previews/topic_list_item_edits_mixin.rb
    ../serializers/topic_previews/topic_list_item_edits.rb
    ../serializers/topic_previews/topic_view_edits.rb
    ../serializers/topic_previews/search_topic_list_item_serializer_edits.rb
  ].each do |path|
    load File.expand_path(path, __FILE__)
  end
  
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
