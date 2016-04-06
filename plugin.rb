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
      excerpt.gsub!(/(\[#{I18n.t 'excerpt_image'}\])/, "") if excerpt
      excerpt
    end

  end

  require 'topic_list_item_serializer'
  class ::TopicListItemSerializer
    attributes :show_thumbnail, :thumbnails

    def thumbnail_url(image, w, h)
      image.create_thumbnail!(w, h) if !image.has_thumbnail?(w, h)
      image.thumbnail(w, h).url
    end

    def thumbnails
      image = Upload.get_from_url(object.image_url)
      return false if !image
      normal = thumbnail_url(image, 100, 100)
      retina = thumbnail_url(image, 200, 200)
      { normal: normal, retina: retina }
    end

    def show_thumbnail
      object.category && object.category.custom_fields["list_thumbnails"] && !!thumbnails
    end

    def include_excerpt?
      object.category && object.category.custom_fields["list_excerpts"] && !!object.excerpt
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
