# frozen_string_literal: true
Discourse::Application.routes.append do
  post 'topic-previews/authorization/callback' => "topic_previews/authorization#callback"

  scope module: 'topic_previews', constraints: AdminConstraint.new do
    get 'admin/topic-previews' => 'admin#index'

    get 'admin/topic-previews/subscription' => 'admin_subscription#index'
    post 'admin/topic-previews/subscription' => 'admin_subscription#update_subscription'
    get 'admin/topic-previews/subscription/authorize' => 'admin_subscription#authorize'
    get 'admin/topic-previews/subscription/authorize/callback' => 'admin_subscription#authorize_callback'
    delete 'admin/topic-previews/subscription/authorize' => 'admin_subscription#destroy_authentication'

    get 'admin/topic-previews/notice' => 'admin_notice#index'
    put 'admin/topic-previews/notice/:notice_id/dismiss' => 'admin_notice#dismiss'
    put 'admin/topic-previews/notice/:notice_id/hide' => 'admin_notice#hide'
    put 'admin/topic-previews/notice/dismiss' => 'admin_notice#dismiss_all'
    get 'admin/topic-previews/notices' => 'admin_notice#index'
  end
end
