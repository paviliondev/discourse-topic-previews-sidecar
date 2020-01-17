import DiscourseUrl from 'discourse/lib/url';
import discourseComputed from "discourse-common/utils/decorators";
import { testImageUrl, getDefaultThumbnail } from '../lib/utilities';

export default Ember.Component.extend({
  tagName: 'a',
  attributeBindings: ['href'],
  classNameBindings: [':tlp-featured-topic', "showDetails", 'featuredTag'],

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

  @discourseComputed
  featuredTags() {
    return Discourse.SiteSettings.topic_list_featured_images_tag.split('|');
  },

  @discourseComputed('topic.tags')
  featuredTag(tags) {
    return tags.filter(tag => this.get('featuredTags').indexOf(tag) > -1)[0];
  },

  mouseEnter() {
    this.set('showDetails', true);
  },

  mouseLeave() {
    this.set('showDetails', false);
  },

  @discourseComputed('topic.id')
  href(topicId) {
    return `/t/${topicId}`;
  },

  click(e) {
    e.preventDefault();
    DiscourseUrl.routeTo(this.get('href'));
  }
});
