import { registerUnbound } from 'discourse/lib/helpers';
import renderUnboundPreview from 'discourse/plugins/discourse-topic-previews/lib/render-preview';
import buttonHTML from 'discourse/plugins/discourse-topic-previews/lib/list-button';
import TopicListItem from 'discourse/components/topic-list-item';
import DiscoveryTopics from 'discourse/controllers/discovery/topics';
import { default as computed, on, observes } from 'ember-addons/ember-computed-decorators';
import { popupAjaxError } from 'discourse/lib/ajax-error';

var animateHeart = function($elem, start, end, complete) {
  if (Ember.testing) { return Ember.run(this, complete); }

  $elem.stop()
       .css('textIndent', start)
       .animate({ textIndent: end }, {
          complete,
          step(now) {
            $(this).css('transform','scale('+now+')');
          },
          duration: 150
        }, 'linear');
}

export default {
  name: 'preview-edits',
  initialize(){

    registerUnbound('preview-unbound', function(thumbnails) {
      return new Handlebars.SafeString(renderUnboundPreview(thumbnails));
    });

    registerUnbound('list-button', function(button, params) {
      return new Handlebars.SafeString(buttonHTML(button, params));
    });

    DiscoveryTopics.reopen({
      @on('init')
      @observes('category', 'model')
      _toggleCategoryColumn() {
        if (this.get('model')) {
          this.set('model.hideCategory', Discourse.SiteSettings.universal_list_category_badge_move ||
                                         this.get('category.list_category_badge_move') ||
                                         this.get('category.has_children'))
        }
      }
    })

    TopicListItem.reopen({
      notSuggested: true,
      canBookmark: Ember.computed.bool('currentUser'),

      @on('didInsertElement')
      _setupDOM() {
        this._rearrangeDOM()
        if (this.get('showActions')) {
          this._setupActions()
        }
      },

      _rearrangeDOM() {
        this.$('.main-link').children().not('.topic-thumbnail').wrapAll("<div class='topic-details' />")
        if (this.$('.discourse-tags')) {
          this.$('.discourse-tags').insertAfter(this.$('.topic-category'))
        }
        if (this.get('showThumbnail')) {
          var $thumbnail = this.$('.topic-thumbnail')
          if (this.$().parents('#suggested-topics').length > 0) {
            $thumbnail.hide()
          } else {
            $thumbnail.prependTo(this.$('.main-link')[0])
          }
        }
        if (this.get('showActions')) {
          var $excerpt = this.$('.topic-excerpt')
          if ($excerpt) {
            this.$('.topic-actions').insertAfter($excerpt)
            if ($excerpt.siblings('.discourse-tags, .topic-category')) {
              $excerpt.css('max-height', '36px')
            }
          }
        }
      },

      _setupActions() {
        var postId = this.get('topic.topic_post_id'),
            $bookmark = this.$('.topic-bookmark'),
            $like = this.$('.topic-like');
        $bookmark.on('click.topic-bookmark', () => {this.toggleBookmark($bookmark, postId)})
        $like.on('click.topic-like', () => {this.toggleLike($like, postId)})
      },

      @on('willDestroyElement')
      _tearDown() {
        this.$('.topic-bookmark').off('click.topic-bookmark')
        this.$('.topic-like').off('click.topic-like')
      },

      @computed()
      showThumbnail() {
        return this.get('topic.thumbnails') && (Discourse.SiteSettings.universal_list_thumbnails ||
                                                (this.get('category') && this.get('category.list_thumbnails')))
      },

      @computed()
      showExcerpt() {
        return this.get('topic.hasExcerpt') && (Discourse.SiteSettings.universal_list_excerpts ||
                                                (this.get('category') && this.get('category.list_excerpts')))
      },

      @computed()
      showCategoryBadge() {
        const category = this.get('category')
        return Discourse.SiteSettings.universal_list_category_badge_move || (category && category.list_category_badge_move)
      },

      @computed()
      showActions() {
        const category = this.get('category')
        return Discourse.SiteSettings.universal_list_actions || (category && category.list_actions)
      },

      @computed()
      topicActions() {
        var actions = []
        if (this.get('canBookmark')) {
          actions.push(this._bookmarkButton())
          Ember.run.scheduleOnce('afterRender', this, () => {
            this.$('.topic-statuses .op-bookmark').hide()
          })
        }
        if (this.get('topic.topic_post_can_like')) {
          actions.push(this._likeButton())
        }
        return actions
      },

      @computed()
      category() {
        return this.container.lookup('controller:discovery/topics').get('category')
      },

      _bookmarkButton() {
        var classes = 'topic-bookmark',
            title = 'bookmarks.not_bookmarked';
        if (this.get('topic.topic_post_bookmarked')) {
          classes += ' bookmarked';
          title = 'bookmarks.created';
        }
        return { class: classes, title: title, icon: 'bookmark'};
      },

      _likeButton() {
        var classes = "topic-like",
            disabled = false
        if (this.get('topic.topic_post_liked')) {
          classes += ' has-like'
          disabled = !this.get('topic.topic_post_can_unlike')
        }
        return { class: classes, title: 'post.controls.like', icon: 'heart', disabled: disabled}
      },

      toggleBookmark($bookmark, postId) {
        this.sendBookmark(postId, !$bookmark.hasClass('bookmarked'))
        $bookmark.toggleClass('bookmarked')
      },

      toggleLike($like, postId) {
        if ($like.hasClass('has-like')) {
          $like.removeClass('has-like')
          this.removeAction(postId, 2)
        } else {
          $like.addClass('has-like');
          $like.prop("disabled", true)
          const scale = [1.0, 1.5];
          return new Ember.RSVP.Promise(resolve => {
            animateHeart($like, scale[0], scale[1], () => {
              animateHeart($like, scale[1], scale[0], () => {
                this.sendAction(postId, 2);
                resolve();
              });
            });
          });
        }
      },

      sendAction(postId, actionId) {
        Discourse.ajax("/post_actions", {
          type: 'POST',
          data: {
            id: postId,
            post_action_type_id: actionId
          },
          returnXHR: true,
        }).catch(function(error) {
          popupAjaxError(error);
        });
      },

      sendBookmark(postId, bookmarked) {
        return Discourse.ajax("/posts/" + postId + "/bookmark", {
          type: 'PUT',
          data: { bookmarked: bookmarked }
        }).catch(function(error) {
          popupAjaxError(error);
        });
      },

      removeAction(postId, actionId) {
        Discourse.ajax("/post_actions/" + postId, {
          type: 'DELETE',
          data: {
            post_action_type_id: actionId
          }
        }).catch(function(error) {
          popupAjaxError(error);
        });
      },

      @computed()
      expandPinned() {
        const pinned = this.get('topic.pinned');
        if (!pinned) {return this.get('showExcerpt')}
        if (this.get('controller.expandGloballyPinned') && this.get('topic.pinned_globally')) {return true;}
        if (this.get('controller.expandAllPinned')) {return true;}
        return false;
      }
    })

  }
}
