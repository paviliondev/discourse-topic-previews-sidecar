var renderUnboundPreview = function(thumbnails) {
  let previewUrl = thumbnails.retina ? (window.devicePixelRatio >= 2 ? thumbnails.retina : thumbnails.normal) : thumbnails;
  let isMobile = Discourse.Site.currentProp('mobileView');
  let width = isMobile ? '60px' : Discourse.SiteSettings.topic_list_thumbnail_width + 'px';
  let height = isMobile ? '60px' : Discourse.SiteSettings.topic_list_thumbnail_height + 'px';
  let style = 'object-fit:cover;height:' + height + ';width:' + width;
  return '<img class="thumbnail" src="' + previewUrl + '" style="' + style + '" />';
};

export default renderUnboundPreview;
