import DiscourseUrl from 'discourse/lib/url';
import { default as computed } from 'ember-addons/ember-computed-decorators';
import { testImageUrl, getDefaultThumbnail } from '../lib/utilities';

export default Ember.Component.extend({
  tagName: 'a',
  attributeBindings: ['href'],
  classNameBindings: [':tlp-featured-topic', "showDetails"],

  didInsertElement() {
    const topic = this.get('topic');

    if (topic) {
      const defaultThumbnail = getDefaultThumbnail();

      testImageUrl(topic.thumbnails, (imageLoaded) => {
        if (!imageLoaded) {
          Ember.run.scheduleOnce('afterRender', this, () => {
            if (defaultThumbnail) {
              this.$('img.thumbnail').attr('src', defaultThumbnail);
            } else {
              this.$().hide();
            }
          });
        }
      });
    }
  },

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
