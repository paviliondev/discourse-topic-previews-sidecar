import registerUnbound from 'discourse/helpers/register-unbound';
import renderUnboundPreview from 'discourse/plugins/discourse-topic-previews/lib/render-preview';

export default {
  name: 'preview-edits',
  initialize(){

    registerUnbound('preview-unbound', function(url) {
      return new Handlebars.SafeString(renderUnboundPreview(url));
    });

  }
}
