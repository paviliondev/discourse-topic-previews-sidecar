var renderUnboundPreview = function(thumbnails) {
  let previewUrl = thumbnails.retina ? (window.devicePixelRatio >= 2 ? thumbnails.retina : thumbnails.normal) : thumbnails;
  let onError = 'this.onerror=null;this.src=\'\';this.className=\'no-thumbnail\';';
  let width = Discourse.SiteSettings.topic_list_thumbnail_width + 'px';
  let height = Discourse.SiteSettings.topic_list_thumbnail_height + 'px';
  let style = 'object-fit:cover;height:' + height + ';width:' + width;
  return '<img class="thumbnail" src="' + previewUrl + '" onError="' + onError + '" style="' + style + '" />';
};

export default renderUnboundPreview;
