import {ajax} from 'discourse/lib/ajax';
import {popupAjaxError} from 'discourse/lib/ajax-error';

var addLike = function (postId) {
  ajax ('/post_actions', {
    type: 'POST',
    data: {
      id: postId,
      post_action_type_id: 2,
    },
    returnXHR: true,
  }).catch (function (error) {
    popupAjaxError (error);
  });
};

var sendBookmark = function (topic, bookmarked) {
  if (bookmarked) {
    const data = {
      reminder_type: null,
      reminder_at: null,
      name: null,
      post_id: topic.topic_post_id,
    };
    return ajax ('/bookmarks', {
      type: 'POST',
      data,
    }).catch (function (error) {
      popupAjaxError (error);
    });
  } else {
    return ajax (`/t/${topic.id}/remove_bookmarks`, {
      type: 'PUT',
    })
      .then (
        topic.firstPost().then (firstPost => {
          topic.toggleProperty ('bookmarked');
          topic.set ('bookmark_reminder_at', null);
          let clearedBookmarkProps = {
            bookmarked: false,
            bookmark_id: null,
            bookmark_name: null,
            bookmark_reminder_at: null,
          };
          firstPost.setProperties (clearedBookmarkProps);
        })
      )
      .catch (function (error) {
        popupAjaxError (error);
      });
  }
};

var removeLike = function (postId) {
  ajax ('/post_actions/' + postId, {
    type: 'DELETE',
    data: {
      post_action_type_id: 2,
    },
  }).catch (function (error) {
    popupAjaxError (error);
  });
};

export { addLike, sendBookmark, removeLike };
