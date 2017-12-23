import { on } from 'ember-addons/ember-computed-decorators';
import { ajax } from 'discourse/lib/ajax';

export default Ember.Component.extend({
  classNameBindings: [':featured-images', 'hasImages'],
  hasImages: Ember.computed.notEmpty('featuredImageList'),
  featuredImageList: null,

  @on('init')
  images() {
    const tagId = this.siteSettings.topic_list_featured_images_tag;
    ajax(`/tags/${tagId}`, {
      data: {
        featured_images: true,
        tags_created_at: true
      }
    }).then((result) => {
      const topicList = result.topic_list;
      if (topicList && topicList.topics && topicList.topics.length > 0) {
        const topics = topicList.topics.filter((t) => t.thumbnails);
        const count = this.siteSettings.topic_list_featured_images_count;
        this.set('featuredImageList', topics.slice(0, count));
      }
    });
  }
});
