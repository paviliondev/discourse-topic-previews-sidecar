var renderUnboundPreview = function(thumbnails) {
  let previewUrl = thumbnails.retina ? (window.devicePixelRatio >= 2 ? thumbnails.retina : thumbnails.normal) : thumbnails;
  let onError = 'this.onerror=null;this.src=\'\';this.className=\'no-thumbnail\';';
  let size = Discourse.SiteSettings.topic_list_thumbnail_size + 'px';
  let style = 'object-fit:cover;height:' + size + ';width:' + size;
  return '<img class="thumbnail" src="' + previewUrl + '" onError="' + onError + '" style="' + style + '" />';
};

export default renderUnboundPreview;
