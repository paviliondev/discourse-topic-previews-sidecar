# name: discourse-topic-previews
# about: A Discourse plugin that gives you a topic preview image in the topic list
# version: 0.1
# authors: Angus McLeod

register_asset 'stylesheets/previews.scss'

after_initialize do

  Category.register_custom_field_type('list_thumbnails', :boolean)
  Category.register_custom_field_type('list_excerpts', :boolean)
  Topic.register_custom_field_type('thumbnails', :json)

  @nil_thumbs = TopicCustomField.where( name: 'thumbnails', value: nil )
  if @nil_thumbs.length
    @nil_thumbs.each do |thumb|
      hash = { :normal => '', :retina => ''}
      thumb.value = ::JSON.generate(hash)
      thumb.save!
    end
  end

  module ListHelper
    class << self
      def create_thumbnails(image)
        normal = image ? thumbnail_url(image, 100, 100) : ''
        retina = image ? thumbnail_url(image, 200, 200) : ''
        { normal: normal, retina: retina }
      end

      def thumbnail_url (image, w, h)
        image.create_thumbnail!(w, h) if !image.has_thumbnail?(w, h)
        image.thumbnail(w, h).url
      end

      def save_thumbnails(id, thumbnails)
        return if !thumbnails
        topic = Topic.find(id)
        topic.custom_fields['thumbnails'] = thumbnails
        topic.save_custom_fields
      end
    end
  end

  require 'listable_topic_serializer'
  class ::ListableTopicSerializer

    def excerpt
      accepted_id = object.custom_fields["accepted_answer_post_id"].to_i
      if accepted_id > 0
        cooked = Post.where(id: accepted_id).pluck('cooked')
        excerpt = PrettyText.excerpt(cooked[0], 300, {})
      else
        excerpt = object.excerpt
      end
      excerpt.gsub!(/(\[#{I18n.t 'excerpt_image'}\])/, "") if excerpt
      excerpt
    end

  end

  require 'cooked_post_processor'
  class ::CookedPostProcessor

    def get_linked_image(url)
      max_size = SiteSetting.max_image_size_kb.kilobytes
      file = FileHelper.download(url, max_size, "discourse", true) rescue nil
      file ? Upload.create_for(@post.user_id, file, file.path.split('/')[-1], File.size(file.path)) : nil
    end

    def create_topic_thumbnails(url)
      local = UrlHelper.is_local(url)
      image = local ? (Upload.get_from_url(url) rescue nil) : get_linked_image(url)
      thumbnails = ListHelper.create_thumbnails(image)
      ListHelper.save_thumbnails(@post.topic.id, thumbnails)
    end

    def update_topic_image
      if @post.is_first_post?
        img = extract_images_for_topic.first
        return if !img["src"]
        url = img["src"][0...255]
        @post.topic.update_column(:image_url, url)
        create_topic_thumbnails(url)
      end
    end

  end

  require 'topic_list_item_serializer'
  class ::TopicListItemSerializer
    attributes :show_thumbnail, :thumbnails

    def get_thumbnails
      thumbnails = object.custom_fields['thumbnails']
      if thumbnails.is_a?(String)
        thumbnails = ::JSON.parse(thumbnails)
      end
      if thumbnails.is_a?(Array)
        thumbnails = thumbnails[0]
      end
      thumbnails.is_a?(Hash) ? thumbnails : { :normal => '', :retina => ''}
    end

    def get_thumbnails_from_image_url
      image = Upload.get_from_url(object.image_url) rescue false
      ListHelper.create_thumbnails(image)
    end

    def thumbnails_present?
      thumbnails = get_thumbnails
      thumbnails && thumbnails['normal'] && thumbnails['retina']
    end

    def thumbnails
      return unless object.archetype == Archetype.default
      if thumbnails_present?
        get_thumbnails
      else
        return unless object.image_url
        thumbnails = get_thumbnails_from_image_url
        ListHelper.save_thumbnails(object.id, thumbnails)
        thumbnails
      end
    end

    def show_thumbnail
      object.category && object.category.custom_fields["list_thumbnails"] && thumbnails_present?
    end

    def include_excerpt?
      object.category && object.category.custom_fields["list_excerpts"] && !!object.excerpt
    end

  end

  TopicList.preloaded_custom_fields << "accepted_answer_post_id" if TopicList.respond_to? :preloaded_custom_fields
  TopicList.preloaded_custom_fields << "thumbnails" if TopicList.respond_to? :preloaded_custom_fields

  add_to_serializer(:basic_category, :list_excerpts) {object.custom_fields["list_excerpts"]}
  add_to_serializer(:basic_category, :list_thumbnails) {object.custom_fields["list_thumbnails"]}
end
