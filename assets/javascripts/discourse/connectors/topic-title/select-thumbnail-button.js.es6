import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';
import showModal from "discourse/lib/show-modal";
import { default as computed, on, observes } from 'ember-addons/ember-computed-decorators';

export default {
  setupComponent(args, component) {
    component.set('isAuthorised',(this.get('currentUser.id') == this.get('topic.user_id')) || this.get('currentUser.admin') || this.get('currentUser.moderator'));
  },

  actions: {
    showThumbnailSelector() {
      var topic_id = this.get('model.id');
      var topic_title = this.get('model.title');

      ajax(`/topic-previews/thumbnail-selection.json?topic=${topic_id}`).then(result => {
        var controller = showModal('tlp-thumbnail-selector', { model: {
          thumbnails: result,
          topic_id: topic_id,
          topic_title: topic_title
          }}
        );
      }).catch(function(error) {
               popupAjaxError(error);
      });
    }
  }
}
