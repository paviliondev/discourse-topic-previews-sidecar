var renderUnboundPreview = function(thumbnails) {
  let previewUrl = thumbnails.retina ? (window.devicePixelRatio >= 2 ? thumbnails.retina : thumbnails.normal) : thumbnails;
  let isMobile = Discourse.Site.currentProp('mobileView');
  let isSocial = Discourse.SiteSettings.topic_list_social_media_discovery;
  let mobileWidth = isSocial ? (screen.width - 20) + 'px' : '60px';
  let mobileHeight = isSocial ? '200px': '60px'; 
  let maxWidth = isMobile ? mobileWidth : Discourse.SiteSettings.topic_list_thumbnail_width + 'px';
  let maxHeight = isMobile ? mobileHeight : Discourse.SiteSettings.topic_list_thumbnail_height + 'px';
  let style = 'object-fit:cover;max-height:' + maxHeight + ';max-width:' + maxWidth;
  return '<img class="thumbnail" src="' + previewUrl + '" style="' + style + '" />';
};

export default renderUnboundPreview;
