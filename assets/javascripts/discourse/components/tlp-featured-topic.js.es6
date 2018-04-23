import DiscourseUrl from 'discourse/lib/url';

export default Ember.Component.extend({
  classNameBindings: [':tlp-featured-topic', "showDetails"],

  mouseEnter() {
    this.set('showDetails', true);
  },

  mouseLeave() {
    this.set('showDetails', false);
  },

  click() {
    const topicId = this.get('topic.id');
    DiscourseUrl.routeTo(`t/${topicId}`);
  }
});
