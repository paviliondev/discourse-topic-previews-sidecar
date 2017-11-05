var previewUrl = function(thumbnails) {
  if (thumbnails.retina) {
    return window.devicePixelRatio >= 2 ? thumbnails.retina : thumbnails.normal;
  } else {
    return thumbnails;
  };
};

var renderUnboundPreview = function(thumbnails, params) {
  const url = previewUrl(thumbnails);
  if (Discourse.Site.currentProp('mobileView')) {
    return '<img class="thumbnail" src="' + url + '"/>';
  }
  const attrPrefix = params.isSocial ? 'max-' : '';
  const height = Discourse.SiteSettings.topic_list_thumbnail_height;
  const width = Discourse.SiteSettings.topic_list_thumbnail_width;
  const style = `object-fit:cover;${attrPrefix}height:${height}px;${attrPrefix}width:${width}px`;
  return '<img class="thumbnail" src="' + url + '" style="' + style + '" />';
};

var testImageUrl = function(thumbnails, callback) {
  const url = previewUrl(thumbnails);
  let timeout = 5000;
  let timer, img = new Image();
  img.onerror = img.onabort = function () {
    clearTimeout(timer);
    callback(false);
  };
  img.onload = function () {
    clearTimeout(timer);
    callback(true);
  };
  timer = setTimeout(function () {
    callback(false);
  }, timeout);
  img.src = url;
};

var buttonHTML = function(action) {
  action = action || {};

  var html = "<button class='list-button " + action.class + "'";
  if (action.title) { html += 'title="' + I18n.t(action.title) + '"'; }
  if (action.disabled) {html += ' disabled';}
  html += "><i class='fa fa-" + action.icon + "' aria-hidden='true'></i>";
  html += "</button>";
  return html;
};

var animateHeart = function($elem, start, end, complete) {
  if (Ember.testing) { return Ember.run(this, complete); }

  $elem.stop()
       .css('textIndent', start)
       .animate({ textIndent: end }, {
          complete,
          step(now) {
            $(this).css('transform','scale('+now+')');
          },
          duration: 150
        }, 'linear');
};

export { renderUnboundPreview, testImageUrl, buttonHTML, animateHeart };
