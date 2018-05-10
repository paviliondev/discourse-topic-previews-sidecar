import DiscourseUrl from 'discourse/lib/url';
import { default as computed } from 'ember-addons/ember-computed-decorators';

export default Ember.Component.extend({
  tagName: 'a',
  attributeBindings: ['href'],
  classNameBindings: [':tlp-featured-topic', "showDetails"],

  mouseEnter() {
    this.set('showDetails', true);
  },

  mouseLeave() {
    this.set('showDetails', false);
  },

  @computed('topic.id')
  href(topicId) {
    return `/t/${topicId}`;
  },

  click(e) {
    e.preventDefault();
    DiscourseUrl.routeTo(this.get('href'));
  }
});
