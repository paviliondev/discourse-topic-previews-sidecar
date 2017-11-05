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

var sendBookmark = function(postId, bookmarked) {
  return ajax("/posts/" + postId + "/bookmark", {
    type: 'PUT',
    data: { bookmarked: bookmarked }
  }).catch(function(error) {
    popupAjaxError(error);
  });
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
