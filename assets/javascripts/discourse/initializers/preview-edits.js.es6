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

      _setupDom: function() {
        this.$('.topic-preview').prependTo(this.$('.main-link')[0])
      }.on('didInsertElement'),

      expandPinned: function() {
        const pinned = this.get('topic.pinned');
        if (!pinned) {return false;}
        if (this.get('topic.show_excerpt')) {return false;}
        if (this.get('controller.expandGloballyPinned') && this.get('topic.pinned_globally')) {return true;}
        if (this.get('controller.expandAllPinned')) {return true;}
        return false;
      }.property(),

    })

  }
}
