# frozen_string_literal: true

class Jobs::TopicPreviewsUpdateSubscription < ::Jobs::Scheduled
  every 1.hour

  def execute(args = {})
    TopicPreviews::Subscription.update
  end
end
