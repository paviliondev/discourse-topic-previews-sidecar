Discourse::Application.routes.draw do
  mount ::TopicPreviews::Engine, at: '/topic-previews'
end

TopicPreviews::Engine.routes.draw do
  get '/thumbnail-selection' => 'thumbnailselection#index'
end