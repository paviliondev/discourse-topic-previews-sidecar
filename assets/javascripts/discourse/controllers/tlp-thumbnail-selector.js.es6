import { default as computed } from 'ember-addons/ember-computed-decorators';
import ModalFunctionality from 'discourse/mixins/modal-functionality';
import { bufferedProperty } from "discourse/mixins/buffered-content";

export default Ember.Controller.extend(ModalFunctionality, bufferedProperty("model"), {
  thumbnailList: Ember.computed.oneWay('model.thumbnails'),
  modal_topic_title: Ember.computed.oneWay('model.topic_title'),
  buffered: Ember.computed.alias('model.buffered'),
  modal_title: 'thumbnail_selector.title',

  actions: {
    selectThumbnail: function(image_url, thumbnail_post_id){
      const buffered = this.get('buffered');
      this.set("buffered.image_url", image_url);
      this.set("buffered.thumbnail_post_id", thumbnail_post_id);
      this.send('closeModal');
    }
  }
});
