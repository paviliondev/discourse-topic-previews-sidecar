# name: discourse-topic-previews
# about: A Discourse plugin that gives you a topic preview image in the topic list
# version: 0.1
# authors: Angus McLeod

register_asset 'stylesheets/previews.scss'

after_initialize do

  Category.register_custom_field_type('list_thumbnails', :boolean)
  Category.register_custom_field_type('list_excerpts', :boolean)

  require 'listable_topic_serializer'
  class ::ListableTopicSerializer

    def excerpt
      accepted_id = object.custom_fields["accepted_answer_post_id"].to_i

      if accepted_id > 0
        cooked = Post.where(id: accepted_id).pluck('cooked')
        excerpt = PrettyText.excerpt(cooked[0], 300, {})
      else
        excerpt = object.excerpt
      end
      excerpt.gsub!(/(\[image\])/, "") if excerpt
      excerpt
    end

    def include_excerpt?
      true
    end

  end

  require 'topic_list_item_serializer'
  class ::TopicListItemSerializer
    attributes :show_thumbnail, :show_excerpt

    def show_thumbnail
      object.category.custom_fields["list_thumbnails"] && !!object.image_url
    end

    def show_excerpt
      object.category.custom_fields["list_excerpts"] && !!object.excerpt
    end
  end

  require 'basic_category_serializer'
  class ::BasicCategorySerializer
    attributes :list_thumbnails, :list_excerpts

    def list_thumbnails
      object.custom_fields["list_thumbnails"]
    end

    def list_excerpts
      object.custom_fields["list_excerpts"]
    end
  end

  TopicList.preloaded_custom_fields << "accepted_answer_post_id" if TopicList.respond_to? :preloaded_custom_fields
  add_to_serializer(:suggested_topic, :is_suggested) {true}
end
