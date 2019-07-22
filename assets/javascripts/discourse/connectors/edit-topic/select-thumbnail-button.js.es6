import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';
import showModal from "discourse/lib/show-modal";
import { default as computed, on, observes } from 'ember-addons/ember-computed-decorators';

export default {

  actions: {
    showThumbnailSelector() {

      var topic_id = this.get('model.id');
      console.log(`before ajax topic_id is ${topic_id}`);
      var topic_title = this.get('model.title');
      console.log(`before ajax topic_title is ${topic_title}`);
      var buffered = this.get('buffered');

      var controller = showModal('tlp-thumbnail-selector', { model: {
        thumbnails: [],
        topic_id: topic_id,
        topic_title: topic_title,
        buffered: buffered
        }}
      );

      ajax(`/topic-previews/thumbnail-selection.json?topic=${topic_id}`).then(result => {

        console.log (`within promise result model.title is ${this.get('model.title')}`);
        console.log (`within promise result model.topic_title is ${this.get('model.topic_title')}`);
      }).catch(function(error) {
               popupAjaxError(error);
      });
    }
  }
}
