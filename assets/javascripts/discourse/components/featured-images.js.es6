import { on } from 'ember-addons/ember-computed-decorators';

export default Ember.Component.extend({
  classNameBindings: [':featured-images', 'hasImages'],
  hasImages: Ember.computed.notEmpty('featuredList'),
  featuredList: null,

  @on('init')
  images() {
    const tagId = this.siteSettings.topic_list_featured_images_tag;
    this.store.findFiltered('topicList', {filter: 'tags/' + tagId}).then((list) => {
      if (list && list.topics) {
        this.set('featuredList', list.topics);
      }
    });
  }
});
