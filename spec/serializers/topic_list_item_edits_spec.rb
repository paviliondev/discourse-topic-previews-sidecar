# frozen_string_literal: true

require 'rails_helper'
require 'post_creator'
require 'jobs/regular/process_post'

describe TopicListItemSerializer do
  let(:topic) do
    date = Time.zone.now

    Fabricate(:topic,
      title: 'This is a test topic title',
      created_at: date - 2.minutes,
      bumped_at: date
    )
  end

  it "correctly serializes topic" do
    SiteSetting.topic_featured_link_enabled = true
    serialized = TopicListItemSerializer.new(topic, scope: Guardian.new, root: false).as_json

    expect(serialized[:title]).to eq("This is a test topic title")
    expect(serialized[:bumped]).to eq(true)
    expect(serialized[:featured_link]).to eq(nil)
    expect(serialized[:featured_link_root_domain]).to eq(nil)
    expect(serialized[:thumbnails]).to eq(nil)


    featured_link = 'http://meta.discourse.org'
    topic.featured_link = featured_link
    serialized = TopicListItemSerializer.new(topic, scope: Guardian.new, root: false).as_json

    expect(serialized[:featured_link]).to eq(featured_link)
    expect(serialized[:featured_link_root_domain]).to eq('discourse.org')
  end

  fab!(:post) { Fabricate(:post) }

  it "process posts and reflect thumbnails in serializer" do
    post = Fabricate(:post, raw: "<img src='#{Discourse.base_url_no_prefix}/awesome/picture.png'>")
    expect(post.cooked).to match(/http/)

    Jobs::ProcessPost.new.execute(post_id: post.id)
    post.reload
    expect(post.cooked).not_to match(/http/)
 
    serialized = TopicListItemSerializer.new(post.topic, scope: Guardian.new, root: false).as_json
    expect(serialized[:thumbnails]).not_to eq(nil)
  end
end
