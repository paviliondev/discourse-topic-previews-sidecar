import { registerUnbound } from 'discourse-common/lib/helpers';
import renderUnboundPreview from 'discourse/plugins/discourse-topic-previews/lib/render-preview';
import buttonHTML from 'discourse/plugins/discourse-topic-previews/lib/list-button';

registerUnbound('preview-unbound', function(thumbnails, params) {
  return new Handlebars.SafeString(renderUnboundPreview(thumbnails, params));
});

registerUnbound('list-button', function(button, params) {
  return new Handlebars.SafeString(buttonHTML(button, params));
});
