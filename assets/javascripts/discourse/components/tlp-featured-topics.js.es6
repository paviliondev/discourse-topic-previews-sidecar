import { default as computed, on, observes } from 'ember-addons/ember-computed-decorators';
import { cookAsync } from 'discourse/lib/text';

export default Ember.Component.extend({
  classNameBindings: [':tlp-featured-topics', 'hasTopics'],
  hasTopics: Ember.computed.notEmpty('featuredTopics'),
  featuredTopics: null,

  @on('init')
  @observes('featuredTopics')
  setup() {
    this.appEvents.trigger('topic:refresh-timeline-position');
  },

  @on('init')
  setupTitle() {
    const showFeaturedTitle = this.get('showFeaturedTitle');
    if (showFeaturedTitle) {
      const raw = Discourse.SiteSettings.topic_list_featured_title;
      cookAsync(raw).then((cooked) => {
        this.set('featuredTitle', cooked);
      })
    }
  },

  @computed
  showFeaturedTitle() {
    return Discourse.SiteSettings.topic_list_featured_title;
  },

  @computed
  showFeaturedLink() {
    return Discourse.SiteSettings.topic_list_featured_images_tag &&
           Discourse.SiteSettings.topic_list_featured_images_tag_show;
  }
});
