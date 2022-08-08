module TopicExtension

  def generate_thumbnails!(extra_sizes: [])
    return nil unless SiteSetting.create_thumbnails
    return nil unless original = image_upload
    return nil unless original.filesize < SiteSetting.max_image_size_kb.kilobytes
    return nil unless original.width && original.height
    extra_sizes = [] unless extra_sizes.kind_of?(Array)

    if SiteSetting.topic_list_enable_thumbnail_black_border_elimination
      TopicThumbnail.where(upload_id:original.id).destroy_all  
      OptimizedImage.where(upload_id:original.id).destroy_all  
    end

    (Topic.thumbnail_sizes + extra_sizes).each do |dim|
      TopicThumbnail.find_or_create_for!(original, max_width: dim[0], max_height: dim[1])
    end
  end

end