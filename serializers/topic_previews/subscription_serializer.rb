# frozen_string_literal: true
class TopicPreviews::SubscriptionSerializer < ApplicationSerializer
  attributes :server
  has_one :authentication, serializer: TopicPreviews::Subscription::AuthenticationSerializer, embed: :objects
  has_one :subscription, serializer: TopicPreviews::Subscription::SubscriptionSerializer, embed: :objects
end
