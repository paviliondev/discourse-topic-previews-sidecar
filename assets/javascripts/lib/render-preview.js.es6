var renderUnboundPreview = function(thumbnails) {
  var previewUrl = window.devicePixelRatio >= 2 ? thumbnails.retina : thumbnails.normal
  return '<div class="thumbnail" style=\'background-image: url("' + previewUrl + '")\'></div>';
};

export default renderUnboundPreview;
