import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';
import showModal from "discourse/lib/show-modal";
import { default as computed, on, observes } from 'ember-addons/ember-computed-decorators';

export default Ember.Component.extend ({
  classNames: 'select-thumbnail',

  actions: {
    showThumbnailSelector() {

      ajax(`/topic-previews/thumbnail-selection.json?topic=${this.get('banana_id')}`).then(result => {
        var controller = showModal('tlp-thumbnail-selector', { model: {
          thumbnails: result,
          orange_id: this.get('banana_id'),
          orange_title: this.get('banana_title'),
          buffered: this.get('buffered')
          }}
        );
      }).catch(function(error) {
               popupAjaxError(error);
      });
    }
  }
})
