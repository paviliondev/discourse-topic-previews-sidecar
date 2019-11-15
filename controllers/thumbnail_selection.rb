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
        @img_srcs << post.image_url if (!post.image_url.blank? && (!@img_srcs.include? post.image_url))
        @img_srcs.map do |image|
          if (!image.include? "emoji") && (!image.include? "avatar") && (!@thumbnails.any? {|h| h[:image] == image})
            @thumbnails << {image: image, post_id: @post_id}
          end
        end
      end
    end

    respond_to do |format|
        format.json { render json: @thumbnails}
    end
  end
end
