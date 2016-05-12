import registerUnbound from 'discourse/helpers/register-unbound';
import renderUnboundPreview from 'discourse/plugins/discourse-topic-previews/lib/render-preview';
import TopicListItem from 'discourse/components/topic-list-item';
import DiscoveryTopics from 'discourse/controllers/discovery/topics';
import { default as computed, on, observes } from 'ember-addons/ember-computed-decorators';

export default {
  name: 'preview-edits',
  initialize(){

    registerUnbound('preview-unbound', function(thumbnails) {
      return new Handlebars.SafeString(renderUnboundPreview(thumbnails));
    });

    DiscoveryTopics.reopen({
      categoryHasPreviews: Ember.computed.or('category.list_excerpts', 'category.list_thumbnails'),

      @on('init')
      @observes('category', 'model')
      _toggleCategoryColumn() {
        if (this.get('model')) {
          this.set('model.hideCategory', this.get('categoryHasPreviews') || this.get('category.has_children'))
        }
      }
    })

    TopicListItem.reopen({
      notSuggested: true,

      @on('didInsertElement')
      _setup() {
        if (this.$('.discourse-tags')) {
          this.$('.discourse-tags').insertAfter(this.$('.topic-category'))
        }
        if (this.get('topic.show_thumbnail')) {
          var $thumbnail = this.$('.topic-thumbnail')
          if (this.$().parents('#suggested-topics').length > 0) {
            $thumbnail.hide()
          } else {
            $thumbnail.prependTo(this.$('.main-link')[0])
            this.$('.main-link').children().not('.topic-thumbnail').wrapAll("<div class='topic-details' />")
          }
        }
        const category = this.container.lookup('controller:discovery/topics').get('category')
        if (category && (category.list_excerpts || category.list_thumbnails)) {
          $('.topic-category').show()
        } else {
          $('.topic-category').hide()
        }
      },

      @computed()
      expandPinned() {
        const pinned = this.get('topic.pinned');
        if (!pinned) {return this.get('topic.hasExcerpt');}
        if (this.get('controller.expandGloballyPinned') && this.get('topic.pinned_globally')) {return true;}
        if (this.get('controller.expandAllPinned')) {return true;}
        return false;
      }

    })

  }
}
