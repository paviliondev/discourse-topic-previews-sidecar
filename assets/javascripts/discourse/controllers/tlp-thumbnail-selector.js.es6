import { default as computed } from 'ember-addons/ember-computed-decorators';
import ModalFunctionality from 'discourse/mixins/modal-functionality';
import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';

export default Ember.Controller.extend(ModalFunctionality, {
  thumbnailList: Ember.computed.alias('model.thumbnails'),
  topic_id: Ember.computed.alias('model.topic_id'),
  topic_title: Ember.computed.alias('model.topic_title'),
  title: 'thumbnail_selector.title',

  actions: {
    selectThumbnail: function(image, post_id){

      var topic_id = this.get('topic_id');

      ajax(`/thumbnailselection`, {
        method: "PUT",
        data: {image: image, post_id: post_id, topic_id: topic_id }
      }).then(result => {
          this.send('closeModal');
        }).catch(function(error) {
               popupAjaxError(error);
      });
    }
  }
});
