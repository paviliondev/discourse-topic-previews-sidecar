import { registerUnbound } from 'discourse/lib/helpers';
import renderUnboundPreview from 'discourse/plugins/discourse-topic-previews/lib/render-preview';
import buttonHTML from 'discourse/plugins/discourse-topic-previews/lib/list-button';
import TopicListItem from 'discourse/components/topic-list-item';
import TopicList from 'discourse/components/topic-list';
import { default as computed, on, observes } from 'ember-addons/ember-computed-decorators';
import { popupAjaxError } from 'discourse/lib/ajax-error';
import DiscourseURL from 'discourse/lib/url';
import { ajax } from 'discourse/lib/ajax';

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

    TopicList.reopen({
      hideCategoryColumn: function(){
        var router = this.container.lookup("router:main"),
            handlerInfos = router.currentState.routerJsState.handlerInfos,
            handler1 = handlerInfos[1],
            handler2 = handlerInfos[2];

        if (handler1.name === 'topic' || this.get('hideCategory')) {return}

        if (Discourse.SiteSettings.topic_list_category_badge_move) {
          return this.set('hideCategory', true)
        }

        if ( handler2.name === 'discovery.category' ||
             handler2.name === 'discovery.parentCategory') {
          var category_id = handler2.context.category.id,
              category = Discourse.Category.findById(category_id)
          if (category.list_category_badge_move) {
            return this.set('hideCategory', true)
          }
        }
      }.on('didInsertElement')
    })

    TopicListItem.reopen({
      canBookmark: Ember.computed.bool('currentUser'),
      rerenderTriggers: ['bulkSelectEnabled', 'topic.pinned', 'likeDifference'],

      @on('init')
      _init() {
        const mobile = this.get('site.mobileView');
        if (mobile) {
          const topic = this.get('topic');
          if (topic.excerpt && !topic.pinned) {
            topic.set('excerpt', '')
          }
        }
      },

      @on('didInsertElement')
      _setupDOM() {
        if (this.get('site.mobileView')) { return }
        if ($('#suggested-topics').length) {
          this.$('.topic-thumbnail, .topic-category, .topic-actions, .topic-excerpt').hide()
        } else {
          this._rearrangeDOM()
          if (this.get('showActions')) {
            this._setupActions()
          }
        }
      },

      _rearrangeDOM() {
        this.$('.main-link').children().not('.topic-thumbnail').wrapAll("<div class='topic-details' />")
        this.$('.topic-details').children('.topic-statuses, .title, .topic-post-badges').wrapAll("<div class='topic-title'/>")
        this.$('.topic-thumbnail').prependTo(this.$('.main-link')[0])

        var showExcerpt = this.get('showExcerpt'),
            showCategoryBadge = this.get('showCategoryBadge'),
            showActions = this.get('showActions'),
            $excerpt = this.$('.topic-excerpt');

        $excerpt.on('click.topic-excerpt', () => {
          var topic = this.get('topic'),
              url = '/t/' + topic.slug + '/' + topic.id;
          if (topic.topic_post_id) {
            url += '/' + topic.topic_post_id
          }
          DiscourseURL.routeTo(url)
        })

        if (showCategoryBadge) {
          this.$('.discourse-tags').insertAfter(this.$('.topic-category'))
        } else if (showActions) {
          this.$('.discourse-tags').insertAfter(this.$('.topic-actions'))
        } else if (showExcerpt) {
          this.$('.discourse-tags').insertAfter($excerpt)
        }

        if (showActions) {
          this.$('.list-vote-count').prependTo(this.$('.topic-actions'))
          if ($excerpt) {
            this.$('.topic-actions').insertAfter($excerpt)
          }
        } else if (showExcerpt) {
          this.$('.list-vote-count').insertAfter($excerpt)
        }

        if (showExcerpt) {
          var height = 0;
          this.$('.topic-details > :not(.topic-excerpt):not(.discourse-tags)').each(function(){ height += $(this).height() })
          var excerpt = 100 - height;
          $excerpt.css('max-height', (excerpt > 19 ? (excerpt > 35 ? excerpt : 19) : 0))
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
        this.$('.topic-excerpt').off('click.topic-excerpt')
        this.$('.topic-bookmark').off('click.topic-bookmark')
        this.$('.topic-like').off('click.topic-like')
      },

      @computed()
      category() {
        const controller = this.container.lookup('controller:discovery/topics')
        return controller.get('category')
      },

      @computed()
      showThumbnail() {
        return this.get('topic.thumbnails') && (Discourse.SiteSettings.topic_list_thumbnails ||
                                               (this.get('category') && this.get('category.list_thumbnails')))
      },

      @computed()
      showExcerpt() {
        return this.get('topic.excerpt') && (Discourse.SiteSettings.topic_list_excerpts ||
                                            (this.get('category') && this.get('category.list_excerpts')))
      },

      @computed()
      showCategoryBadge() {
        const category = this.get('category')
        return Discourse.SiteSettings.topic_list_category_badge_move || (category && category.list_category_badge_move)
      },

      @computed()
      showActions() {
        const category = this.get('category')
        return Discourse.SiteSettings.topic_list_actions || (category && category.list_actions)
      },

      @computed('likeDifference')
      topicActions() {
        var actions = []
        if (this.get('topic.topic_post_can_like')) {
          actions.push(this._likeButton())
        }
        if (this.get('canBookmark')) {
          actions.push(this._bookmarkButton())
          Ember.run.scheduleOnce('afterRender', this, () => {
            var $bookmarkStatus = this.$('.topic-statuses .op-bookmark')
            if ($bookmarkStatus) {
              $bookmarkStatus.hide()
            }
          })
        }
        return actions
      },

      likeCount() {
        var likeDifference = this.get('likeDifference'),
            count = (likeDifference == null ? this.get('topic.topic_post_like_count') : likeDifference) || 0;
        return count
      },

      @computed('likeDifference')
      likeCountDisplay() {
        var count = this.likeCount(),
            message = count === 1 ? "post.has_likes.one" : "post.has_likes.other";
        return count > 0 ? I18n.t(message, { count }) : false
      },

      @computed('hasLiked')
      hasLikedDisplay() {
        var hasLiked = this.get('hasLiked')
        return hasLiked == null ? this.get('topic.topic_post_liked') : hasLiked
      },

      changeLikeCount(change) {
        var count = this.likeCount(),
            newCount = count + (change || 0);
        this.set('hasLiked', Boolean(change > 0))
        this.set('likeDifference', newCount)
        this._likeRerender()
      },

      _likeRerender(){
        Ember.run.scheduleOnce('afterRender', this, () => {
          this._rearrangeDOM()
          this._setupActions()
        })
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
        if (this.get('hasLikedDisplay')) {
          classes += ' has-like'
          disabled = this.get('topic.topic_post_can_unlike') ? false : this.get('likeDifference') == null
        }
        return { class: classes, title: 'post.controls.like', icon: 'heart', disabled: disabled}
      },

      toggleBookmark($bookmark, postId) {
        this.sendBookmark(postId, !$bookmark.hasClass('bookmarked'))
        $bookmark.toggleClass('bookmarked')
      },

      toggleLike($like, postId) {
        if (this.get('hasLikedDisplay')) {
          this.removeAction(postId)
          this.changeLikeCount(-1)
        } else {
          const scale = [1.0, 1.5];
          return new Ember.RSVP.Promise(resolve => {
            animateHeart($like, scale[0], scale[1], () => {
              animateHeart($like, scale[1], scale[0], () => {
                this.sendAction(postId);
                this.changeLikeCount(1)
                resolve();
              });
            });
          });
        }
      },

      sendAction(postId) {
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
      },

      sendBookmark(postId, bookmarked) {
        return ajax("/posts/" + postId + "/bookmark", {
          type: 'PUT',
          data: { bookmarked: bookmarked }
        }).catch(function(error) {
          popupAjaxError(error);
        });
      },

      removeAction(postId) {
        ajax("/post_actions/" + postId, {
          type: 'DELETE',
          data: {
            post_action_type_id: 2
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
