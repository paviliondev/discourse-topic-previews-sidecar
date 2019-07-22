import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';
import showModal from "discourse/lib/show-modal";
import { default as computed, on, observes } from 'ember-addons/ember-computed-decorators';

export default {
  actions: {
    showThumbnailSelector() {

      ajax(`/topic-previews/thumbnail-selection.json?topic=${this.get('model.id')}`).then(result => {
        var controller = showModal('tlp-thumbnail-selector', { model: {
          thumbnails: result,
          topic_id: this.get('model.id'),
          topic_title: this.get('model.title'),
          buffered: this.get('buffered')
          }}
        );
      }).catch(function(error) {
               popupAjaxError(error);
      });
    }
  }
}
