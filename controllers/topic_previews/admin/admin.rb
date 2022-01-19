# frozen_string_literal: true
class TopicPreviews::AdminController < ::Admin::AdminController
  before_action :ensure_admin

  def index
    render_json_dump(
      #TODO replace with appropriate static?
      #api_section: ["business"].include?(TopicPreviews::Subscription.type),
      active_notice_count: TopicPreviews::Notice.active_count,
      featured_notices: ActiveModel::ArraySerializer.new(
        TopicPreviews::Notice.list(
          type: TopicPreviews::Notice.types[:info],
          archetype: TopicPreviews::Notice.archetypes[:subscription_message]
        ),
        each_serializer: TopicPreviews::NoticeSerializer
      )
    )
  end
end
