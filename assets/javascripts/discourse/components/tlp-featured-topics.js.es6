import { on, observes } from 'ember-addons/ember-computed-decorators';

export default Ember.Component.extend({
  classNameBindings: [':tlp-featured-topics', 'hasTopics'],
  hasTopics: Ember.computed.notEmpty('featuredTopics'),
  featuredTopics: null,

  @on('init')
  @observes('featuredTopics')
  setup() {
    this.appEvents.trigger('topic:refresh-timeline-position');
  }
});
