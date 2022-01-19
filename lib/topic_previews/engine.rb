# frozen_string_literal: true

module ::TopicPreviews
  PLUGIN_NAME ||= 'topic_previews'

  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace TopicPreviews
  end
end
