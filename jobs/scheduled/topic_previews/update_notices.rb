# frozen_string_literal: true

class Jobs::TopicPreviewsUpdateNotices < ::Jobs::Scheduled
  every 5.minutes

  def execute(args = {})
    TopicPreviews::Notice.update
  end
end
