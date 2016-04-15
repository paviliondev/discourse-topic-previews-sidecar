import registerUnbound from 'discourse/helpers/register-unbound';
import renderUnboundPreview from 'discourse/plugins/discourse-topic-previews/lib/render-preview';
import TopicListItem from 'discourse/views/topic-list-item';
import DiscoveryTopics from 'discourse/controllers/discovery/topics';
import { default as computed, on, observes } from 'ember-addons/ember-computed-decorators';

export default {
  name: 'preview-edits',
  initialize(){

    registerUnbound('preview-unbound', function(thumbnails) {
      return new Handlebars.SafeString(renderUnboundPreview(thumbnails));
    });

    DiscoveryTopics.reopen({
      filterCategoryHasPreviews: Ember.computed.or('category.list_excerpts', 'category.list_thumbnails'),

      @on('init')
      @observes('category', 'model')
      _toggleCategoryColumn() {
        if (this.get('model')) {
          this.set('model.hideCategory', this.get('filterCategoryHasPreviews') || this.get('category.has_children'))
        }
      }
    })

    TopicListItem.reopen({
      discoveryCategory: Ember.computed.alias('parentView.parentView.controller.category'),
      filterCategoryHasPreviews: Ember.computed.or('discoveryCategory.list_excerpts', 'discoveryCategory.list_thumbnails'),
      notSuggested: true,

      @on('didInsertElement')
      _setupDom() {
        if (this.$('.discourse-tags')) {
          this.$('.discourse-tags').insertAfter(this.$('.topic-category'))
        }
        if (this.get('topic.show_thumbnail')) {
          var $thumbnail = this.$('.topic-thumbnail')
          if (this.$().parents('#suggested-topics').length > 0) {
            $thumbnail.hide()
          } else {
            $thumbnail.prependTo(this.$('.main-link')[0])
          }
        }
      },

      @computed('filterCategoryHasPreviews')
      showCategoryBadge() {
        return this.get('filterCategoryHasPreviews') && !this.get('topic.isPinnedUncategorized')
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
