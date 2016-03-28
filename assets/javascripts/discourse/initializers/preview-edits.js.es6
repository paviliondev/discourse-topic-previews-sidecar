import registerUnbound from 'discourse/helpers/register-unbound';
import renderUnboundPreview from 'discourse/plugins/discourse-topic-previews/lib/render-preview';
import TopicListItem from 'discourse/views/topic-list-item';

export default {
  name: 'preview-edits',
  initialize(){

    registerUnbound('preview-unbound', function(url) {
      return new Handlebars.SafeString(renderUnboundPreview(url));
    });

    TopicListItem.reopen({
      setup: function() {
        this.$('.topic-preview').prependTo(this.$('.main-link')[0])
      }.on('didInsertElement')
    })

  }
}
