class Post
  def link_post_uploads(fragments: nil)
    upload_ids = []

    each_upload_url(fragments: fragments) do |src, _, sha1|
      upload = nil
      upload = Upload.find_by(sha1: sha1) if sha1.present?
      upload ||= Upload.get_from_url(src)
      upload_ids << upload.id if upload.present?
    end

    upload_ids |= Upload.where(id: downloaded_images.values).pluck(:id)
    values = upload_ids.map! { |upload_id| "(#{self.id},#{upload_id})" }.join(",")

    if !self.custom_fields['thumbnail_upload_id'].nil?
      thumbnail_upload_id = self.custom_fields['thumbnail_upload_id']
      if !values.include? "," + thumbnail_upload_id.to_s
        values << "," if values != ""
        values <<  "(#{self.id},#{thumbnail_upload_id})"
      end
      self.custom_fields['thumbnail_upload_id'] = nil
    end

    PostUpload.transaction do
      PostUpload.where(post_id: self.id).delete_all

      if values.size > 0
        DB.exec("INSERT INTO post_uploads (post_id, upload_id) VALUES #{values}")
      end
    end
  end
end
