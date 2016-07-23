var renderUnboundPreview = function(thumbnails) {
  var previewUrl = window.devicePixelRatio >= 2 ? thumbnails.retina : thumbnails.normal
  return '<img class="thumbnail" src="' + previewUrl + '" onError="this.onerror=null;this.src=\'\';this.className=\'no-thumbnail\';" />';
};

export default renderUnboundPreview;
