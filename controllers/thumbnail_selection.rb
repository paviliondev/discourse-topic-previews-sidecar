class ::TopicPreviews::ThumbnailselectionController < ::ApplicationController

  def index
    params.require(:topic)

    raise Discourse::InvalidAccess.new unless current_user

    topic_id = params[:topic].to_i
    topic = Topic.find(topic_id)
    user_id = topic.user_id

    thumbnails = []

    if current_user.id = user_id || current_user.admin == true
      thumbnails = TopicPreviews::ThumbnailSelectionHelper.get_thumbnails_from_topic(topic)
    end

    respond_to do |format|
        format.json { render json: thumbnails}
    end
  end
end
