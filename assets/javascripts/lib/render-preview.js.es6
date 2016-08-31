var renderUnboundPreview = function(thumbnails) {
  let previewUrl = thumbnails.retina ? (window.devicePixelRatio >= 2 ? thumbnails.retina : thumbnails.normal) : thumbnails;
  let isMobile = Discourse.Site.currentProp('mobileView');
  let maxWidth = isMobile ? '60px' : Discourse.SiteSettings.topic_list_thumbnail_width + 'px';
  let maxHeight = isMobile ? '60px' : Discourse.SiteSettings.topic_list_thumbnail_height + 'px';
  let style = 'object-fit:cover;max-height:' + maxHeight + ';max-width:' + maxWidth;
  return '<img class="thumbnail" src="' + previewUrl + '" style="' + style + '" />';
};

export default renderUnboundPreview;
