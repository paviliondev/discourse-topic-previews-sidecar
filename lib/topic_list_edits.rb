class ::Topic
  attr_accessor :previewed_post
  attr_accessor :previewed_post_actions
end

module TopicListAddon
  def load_topics
    @topics = super

    if SiteSetting.topic_list_previews_enabled
      # TODO: better to keep track of previewed posts' id so they can be loaded at once
      posts_map = {}
      post_actions_map = {}
      accepted_anwser_post_ids = []
      normal_topic_ids = []
      previewed_post_ids = []
      @topics.each do |topic|
        if post_id = topic.custom_fields["accepted_answer_post_id"]&.to_i
          accepted_anwser_post_ids << post_id
        else
          normal_topic_ids << topic.id
        end
      end

      Post.where("id IN (?)", accepted_anwser_post_ids).each do |post|
        posts_map[post.topic_id] = post
        previewed_post_ids << post.id
      end
      Post.where("post_number = 1 AND topic_id IN (?)", normal_topic_ids).each do |post|
        posts_map[post.topic_id] = post
        previewed_post_ids << post.id
      end
      if @current_user
        PostAction.where("post_id IN (?) AND user_id = ?", previewed_post_ids, @current_user.id).each do |post_action|
          (post_actions_map[post_action.post_id] ||= []) << post_action
        end
      end

      @topics.each do |topic|
        topic.previewed_post = posts_map[topic.id]
        topic.previewed_post_actions = post_actions_map[topic.previewed_post.id] if topic.previewed_post
      end
    end

    @topics
  end
end

class ::TopicList
  prepend TopicListAddon
end
