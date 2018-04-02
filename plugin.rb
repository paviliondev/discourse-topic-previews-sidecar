# name: discourse-topic-list-previews
# about: Allows you to add topic previews and other topic features to topic lists
# version: 0.4
# authors: Angus McLeod
# url: https://github.com/angusmcleod/discourse-topic-previews

register_asset 'stylesheets/previews_common.scss'
register_asset 'stylesheets/previews_mobile.scss'

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

  add_to_serializer(:basic_category, :topic_list_social) { object.custom_fields["topic_list_social"] }
  add_to_serializer(:basic_category, :topic_list_excerpt) { object.custom_fields["topic_list_excerpt"] }
  add_to_serializer(:basic_category, :topic_list_thumbnail) { object.custom_fields["topic_list_thumbnail"] }
  add_to_serializer(:basic_category, :topic_list_action) { object.custom_fields["topic_list_action"] }
  add_to_serializer(:basic_category, :topic_list_category_badge_move) { object.custom_fields["topic_list_category_badge_move"] }
  add_to_serializer(:basic_category, :topic_list_default_thumbnail) { object.custom_fields["topic_list_default_thumbnail"] }
  add_to_serializer(:basic_category, :topic_list_thumbnail_width) { object.custom_fields['topic_list_thumbnail_width'] }
  add_to_serializer(:basic_category, :topic_list_thumbnail_height) { object.custom_fields['topic_list_thumbnail_height'] }
  add_to_serializer(:basic_category, :topic_list_featured_images) { object.custom_fields['topic_list_featured_images'] }
end
