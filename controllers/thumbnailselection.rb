class ::TopicPreviews::ThumbnailselectionController < ::ApplicationController
  def index
    params.require(:topic)

    raise Discourse::InvalidAccess.new unless current_user

    topic_number = params[:topic].to_i

    @topic = Topic.find(topic_number)
    @user_id = @topic.user_id
    @posts = @topic.posts
    @thumbnails = []

    if current_user.id = @user_id || current_user.admin == true
      @posts.map do |post|
        @post_id = post.id
        @doc = Nokogiri::HTML( post.cooked )
        @img_srcs = @doc.css('img').map{ |i| i['src'] }
        @img_srcs.map do |image|
          if (!image.include? "emoji") && (!image.include? "avatar")
            @thumbnails << {image: image, post_id: @post_id}
          end
        end
      end
    end

    respond_to do |format|
        format.json { render json: @thumbnails}
    end
  end

  def update
    params.require(:topic_id)
    params.require(:post_id)
    params.require(:image)

    raise Discourse::InvalidAccess.new unless current_user

    @topic_id = params[:topic_id].to_i

    @topic = Topic.find(@topic_id)
    @post_id = params[:post_id].to_i
    @post = Post.find(@post_id)
    @user_id = @topic.user_id
    @thumbnail = params[:image].to_s

    if current_user.id = @user_id || current_user.admin == true
        @topic.update_column(:image_url, @thumbnail) # topic
        return if SiteSetting.topic_list_hotlink_thumbnails ||
                  !SiteSetting.topic_list_previews_enabled

        if upload_id = ListHelper.create_topic_thumbnails(@post, @thumbnail)

          ## ensure there is a post_upload record so the upload is not removed in the cleanup
          unless PostUpload.where(post_id: @post.id).exists?
            PostUpload.create(post_id: @post.id, upload_id: upload_id)
          end
        end
        @topic.save!
    end
  end
end
