import registerUnbound from 'discourse/helpers/register-unbound';
import renderUnboundPreview from 'discourse/plugins/discourse-topic-previews/lib/render-preview';
import TopicListItem from 'discourse/views/topic-list-item';

export default {
  name: 'preview-edits',
  initialize(){

    registerUnbound('preview-unbound', function(thumbnails) {
      return new Handlebars.SafeString(renderUnboundPreview(thumbnails));
    });

    TopicListItem.reopen({

      _setupDom: function() {
        this.$('td.category').remove()
        this.$().parents('table').find('th.category').remove()
        var $tags = this.$('.discourse-tags'),
            $category = this.$('.topic-category'),
            thumbnail = this.get('topic.show_thumbnail'),
            excerpt = this.get('topic.hasExcerpt');
        if ($tags.length) {$tags.insertAfter($category)}
        if (excerpt || thumbnail) {
          if (thumbnail) {this.$('.topic-preview').prependTo(this.$('.main-link')[0])}
        } else { this.$('a.title').css('display', 'inline-block')}
        this.$('td.posters a:gt(0):lt(-1)').hide()
      }.on('didInsertElement'),

      expandPinned: function() {
        const pinned = this.get('topic.pinned');
        if (!pinned) {return this.get('topic.hasExcerpt');}
        if (this.get('controller.expandGloballyPinned') && this.get('topic.pinned_globally')) {return true;}
        if (this.get('controller.expandAllPinned')) {return true;}
        return false;
      }.property()

    })

  }
}
