# name: discourse-topic-previews
# about: A Discourse plugin that gives you a topic preview image in the topic list
# version: 0.1
# authors: Angus McLeod

register_asset 'stylesheets/previews.scss'

after_initialize do

  require 'listable_topic_serializer'
  class ::ListableTopicSerializer

    def excerpt
      accepted_id = object.custom_fields["accepted_answer_post_id"].to_i
      if accepted_id > 0
        cooked = Post.where(id: accepted_id).pluck('cooked')
        excerpt = PrettyText.excerpt(cooked[0], 200, {})
        excerpt.slice! "[image]"
        excerpt
      else
        object.excerpt
      end
    end

    def include_excerpt?
      true
    end
  end

  add_to_serializer(:suggested_topic, :is_suggested) {true}
end
