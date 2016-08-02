var renderUnboundPreview = function(thumbnails) {
  let previewUrl = thumbnails.retina ? (window.devicePixelRatio >= 2 ? thumbnails.retina : thumbnails.normal) : thumbnails
  return '<img class="thumbnail" src="' + previewUrl + '" onError="this.onerror=null;this.src=\'\';this.className=\'no-thumbnail\';" />';
};

export default renderUnboundPreview;
