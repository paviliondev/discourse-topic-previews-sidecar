# name: discourse-topic-previews-sidecar
# about: Sidecar Plugin to support Topic List Preview Theme Component
# version: 5.1.1
# authors: Robert Barrow, Angus McLeod
# url: https://github.com/paviliondev/discourse-topic-previews

gem 'pkg-config', '1.5.6', {require: true}
gem 'observer', '0.1.2', {require: true}
gem 'rmagick', '6.0.1', {require: false}
gem 'prizm', '0.0.3', {require: true}

enabled_site_setting :topic_list_previews_enabled

DiscoursePluginRegistry.serialized_current_user_fields << "tlp_user_prefs_prefer_low_res_thumbnails"

module ::TopicPreviews
  PLUGIN_NAME = "topic-previews".freeze
end

require_relative "lib/topic_previews/engine"

after_initialize do
  reloadable_patch do
    Category.prepend(TopicPreviews::CategoryExtension)
    Topic.prepend(TopicPreviews::TopicExtension)
    TopicView.prepend(TopicPreviews::TopicViewExtension)
    TopicViewSerializer.prepend(TopicPreviews::TopicViewSerializerExtension)
    TopicQuery.prepend(TopicPreviews::TopicQueryExtension)
    ListHelper.prepend(TopicPreviews::ListHelperExtension)
    TopicList.prepend(TopicPreviews::TopicListExtension)
    TopicListSerializer.prepend(TopicPreviews::TopicListSerializerExtension)
    TopicListItemSerializer.prepend(TopicPreviews::TopicListItemSerializerExtension)
    OptimizedImage.singleton_class.prepend(TopicPreviews::OptimizedImageExtension)
    CookedPostProcessor.prepend(TopicPreviews::CookedPostProcessorExtension)
    Guardian.prepend(TopicPreviews::GuardianExtension)
    PostGuardian.prepend(TopicPreviews::PostGuardianExtension)
    SearchTopicListItemSerializer.prepend(TopicPreviews::SearchTopicListItemSerializerExtension)
  end

  User.register_custom_field_type('tlp_user_prefs_prefer_low_res_thumbnails', :boolean)
  Topic.register_custom_field_type('user_chosen_thumbnail_url', :string)
  Topic.register_custom_field_type('dominant_colour', :json)

  register_editable_user_custom_field :tlp_user_prefs_prefer_low_res_thumbnails

 

  TopicList.preloaded_custom_fields << "accepted_answer_post_id" if TopicList.respond_to? :preloaded_custom_fields
  TopicList.preloaded_custom_fields << "dominant_colour" if TopicList.respond_to? :preloaded_custom_fields
  TopicView.preloaded_custom_fields << "accepted_answer_post_id" if TopicView.respond_to? :preloaded_custom_fields
  TopicView.preloaded_custom_fields << "dominant_colour" if TopicView.respond_to? :preloaded_custom_fields
  Topic.preloaded_custom_fields << "accepted_answer_post_id" if Topic.respond_to? :preloaded_custom_fields
  Topic.preloaded_custom_fields << "dominant_colour" if Topic.respond_to? :preloaded_custom_fields
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

  DiscourseEvent.trigger(:topic_previews_ready)
end
