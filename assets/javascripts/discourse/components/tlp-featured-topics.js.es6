import { default as computed, on, observes } from 'ember-addons/ember-computed-decorators';

export default Ember.Component.extend({
  classNameBindings: [':tlp-featured-topics', 'hasTopics'],
  hasTopics: Ember.computed.notEmpty('featuredTopics'),
  featuredTopics: null,

  @on('init')
  @observes('featuredTopics')
  setup() {
    this.appEvents.trigger('topic:refresh-timeline-position');
  },

  @computed
  showFeaturedLink() {
    return Discourse.SiteSettings.topic_list_featured_images_tag &&
           Discourse.SiteSettings.topic_list_featured_images_tag_show;
  }
});
