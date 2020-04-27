import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';

var addLike = function(postId) {
  ajax("/post_actions", {
    type: 'POST',
    data: {
      id: postId,
      post_action_type_id: 2
    },
    returnXHR: true,
  }).catch(function(error) {
    popupAjaxError(error);
  });
};

var sendBookmark = function (postId, bookmarked) {

  if (bookmarked) {
    const data = {
      reminder_type: null,
      reminder_at: null,
      name: '',
      post_id: postId,
    };

    return ajax ('/bookmarks', {type: 'POST', data}).catch (function (error) {
      popupAjaxError (error);
    });
  } else {
    return ajax (`/posts/${postId}/bookmark`, {
      type: 'DELETE'
    }).catch (function (error) {
      popupAjaxError (error);
    });
  }
};

var removeLike = function(postId) {
  ajax("/post_actions/" + postId, {
    type: 'DELETE',
    data: {
      post_action_type_id: 2
    }
  }).catch(function(error) {
    popupAjaxError(error);
  });
};

export { addLike, sendBookmark, removeLike };
