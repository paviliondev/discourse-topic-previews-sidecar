var renderUnboundPreview = function(thumbnails) {
  let previewUrl = thumbnails.retina ? (window.devicePixelRatio >= 2 ? thumbnails.retina : thumbnails.normal) : thumbnails;
  if (Discourse.Site.currentProp('mobileView'))
  	return '<img class="thumbnail" src="' + previewUrl + '"/>';
  let style = 'object-fit:cover;max-height:' + Discourse.SiteSettings.topic_list_thumbnail_height + 'px' + ';max-width:' + Discourse.SiteSettings.topic_list_thumbnail_width + 'px';
  return '<img class="thumbnail" src="' + previewUrl + '" style="' + style + '" />';
};

export default renderUnboundPreview;
