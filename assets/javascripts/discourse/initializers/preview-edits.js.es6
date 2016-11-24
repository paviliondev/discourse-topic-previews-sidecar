import { registerUnbound } from 'discourse-common/lib/helpers';
import renderUnboundPreview from 'discourse/plugins/discourse-topic-previews/lib/render-preview';
import buttonHTML from 'discourse/plugins/discourse-topic-previews/lib/list-button';
import testImageUrl from 'discourse/plugins/discourse-topic-previews/lib/test-image-url';
import TopicListItem from 'discourse/components/topic-list-item';
import TopicList from 'discourse/components/topic-list';
import { default as computed, on, observes } from 'ember-addons/ember-computed-decorators';
import { popupAjaxError } from 'discourse/lib/ajax-error';
import DiscourseURL from 'discourse/lib/url';
import { ajax } from 'discourse/lib/ajax';
import EditCategorySettings from 'discourse/components/edit-category-settings';

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

    EditCategorySettings.reopen({
      choices: ['latest', 'new', 'unread', 'top', 'latest-mobile', 'new-mobile', 'unread-mobile', 'top-mobile']
    })

    TopicList.reopen({
      category: Ember.computed.alias('parentView.model.category'),

      // this assumes topics change whenever the route changes
      @computed('topics')
      isDiscoveryTopicList() {
        const parentComponentName = Object.getPrototypeOf(this.get('parentView'))._debugContainerKey.split(':')
        return parentComponentName.length > 1 && parentComponentName[1] == 'discovery-topics-list'
      },

      @computed('parentView.model.filter')
      filter() {
        let filter = this.get('parentView.model.filter')
        if (this.get('site.mobileView')) {
          filter += '-mobile'
        }
        return filter
      },

      settingEnabled(setting) {
        if (!this.get('isDiscoveryTopicList')) { return false }

        const category = this.get('category'),
              filter = this.get('filter');

        let filterArr = filter ? filter.split('/') : [],
            filterType = filterArr[filterArr.length - 1],
            catSetting = category ? category.get(setting) : false,
            siteSetting = Discourse.SiteSettings[setting] ? Discourse.SiteSettings[setting].toString() : false;

        let catEnabled = catSetting && catSetting.split('|').indexOf(filterType) > -1,
            siteEnabled = siteSetting && siteSetting.split('|').indexOf(filterType) > -1,
            siteDefaults = Discourse.SiteSettings.topic_list_set_category_defaults;

        return category ? (catEnabled || siteDefaults && siteEnabled) : siteEnabled
      },

      @on('didInsertElement')
      hideCategoryColumn(){
        if (this.settingEnabled('topic_list_category_badge_move')) {
          this.set('hideCategory', true)
        }
      },

      @on('init')
      @observes('isDiscoveryTopicList', 'filter', 'category')
      setDisplayProperties() {
        this.setProperties({
          socialStyle: this.settingEnabled('topic_list_social'),
          showThumbnail: this.settingEnabled('topic_list_thumbnail'),
          showExcerpt: this.settingEnabled('topic_list_excerpt'),
          showActions: this.settingEnabled('topic_list_action'),
          showCategoryBadge: this.settingEnabled('topic_list_category_badge_move')
        })
      },

      @on("didInsertElement")
      @observes("socialStyle")
      setupListStyle() {
        if (!this.$()) {return}
        const social = this.get('socialStyle');
        this.set('skipHeader', social || this.get('site.mobileView'));
        this.$().parents('#list-area').toggleClass('social-style', social);
      },

      @on('willDestroyElement')
      _tearDown() {
        this.$().parents('#list-area').removeClass('social-style');
      },
    })

    TopicListItem.reopen({
      canBookmark: Ember.computed.bool('currentUser'),
      rerenderTriggers: ['bulkSelectEnabled', 'topic.pinned', 'likeDifference', 'topic.thumbnails'],
      socialStyle: Ember.computed.alias('parentView.socialStyle'),
      showThumbnail: Ember.computed.and('thumbnails', 'parentView.showThumbnail'),
      showExcerpt: Ember.computed.and('topic.excerpt', 'parentView.showExcerpt'),
      showActions: Ember.computed.alias('parentView.showActions'),
      showCategoryBadge: Ember.computed.alias('parentView.showCategoryBadge'),

      // Lifecyle logic

      @on('init')
      _init() {
        const topic = this.get('topic');
        if (topic.get('thumbnails')) {
          testImageUrl(topic.get('thumbnails.normal'), function(imageLoaded) {
            if (!imageLoaded) {
              topic.set('thumbnails', null)
            }
          });
        }
      },

      @on('didInsertElement')
      _setupDOM() {
        if (this.get('showThumbnail')) {
          this._sizeThumbnails()
        }
        if ($('#suggested-topics').length) {
          this.$('.topic-thumbnail, .topic-category, .topic-actions, .topic-excerpt').hide()
        } else {
          Ember.run.scheduleOnce('render', this, () => {
            this._rearrangeDOM()
            if (this.get('showActions')) {
              this._setupActions()
            }
          })
        }
      },

      _rearrangeDOM() {
        if (this.get('site.mobileView')) {return}
        if (!this.$('.main-link')) {return}
        this.$('.main-link').children().not('.topic-thumbnail').wrapAll("<div class='topic-details' />");
        this.$('.topic-details').children('.topic-statuses, .title, .topic-post-badges').wrapAll("<div class='topic-title'/>");
        this.$('.topic-thumbnail').prependTo(this.$('.main-link')[0]);
        this.$('.topic-title a.visited').closest('.topic-details').addClass('visited');

        const showExcerpt = this.get('showExcerpt'),
              showCategoryBadge = this.get('showCategoryBadge'),
              showActions = this.get('showActions'),
              $excerpt = this.$('.topic-excerpt'),
              socialStyle = this.get('socialStyle');

        this._setupExcerptClick($excerpt)

        if (showCategoryBadge) {
          this.$('.discourse-tags').insertAfter(this.$('.topic-category'))
        } else if (showActions) {
          this.$('.discourse-tags').insertAfter(this.$('.topic-actions'))
        } else if (showExcerpt) {
          this.$('.discourse-tags').insertAfter($excerpt)
        }

        if (showActions) {
          this.$('.list-vote-count').prependTo(this.$('.topic-actions'))
          if (showExcerpt) {
            this.$('.topic-actions').insertAfter(this.$('.topic-excerpt'))
          }
        } else if (showExcerpt) {
          this.$('.list-vote-count').insertAfter($excerpt)
        }

        if (!socialStyle && showExcerpt) {
          let height = 0;
          this.$('.topic-details > :not(.topic-excerpt):not(.discourse-tags)').each(function(){ height += $(this).height() })
          let excerpt = 100 - height;
          $excerpt.css('max-height', (excerpt >= 17 ? (excerpt > 35 ? excerpt : 17) : 0))
        }

        if (socialStyle) {
          this.$('.topic-intro').prependTo(this.$('.main-link'))
          this.$('.topic-title').prependTo(this.$('.main-link'))
          if (this.$('.topic-details').children().length < 1)
            this.$('.topic-details').hide()
        }
      },

      _setupExcerptClick($excerpt) {
        $excerpt.on('click.topic-excerpt', () => {
          let topic = this.get('topic'),
              url = '/t/' + topic.slug + '/' + topic.id;
          if (topic.topic_post_id) {
            url += '/' + topic.topic_post_id
          }
          DiscourseURL.routeTo(url)
        })
      },

      _setupActions() {
        let postId = this.get('topic.topic_post_id'),
            $bookmark = this.$('.topic-bookmark'),
            $like = this.$('.topic-like');

        $bookmark.on('click.topic-bookmark', () => {
          this.toggleBookmark($bookmark, postId)
        })

        $like.on('click.topic-like', () => {
          if (this.get('currentUser')) {
            this.toggleLike($like, postId);
          } else {
            const controller = this.container.lookup('controller:application');
            controller.send('showLogin');
          }
        })
      },

      @on('willDestroyElement')
      _tearDown() {
        this.$('.topic-excerpt').off('click.topic-excerpt')
        this.$('.topic-bookmark').off('click.topic-bookmark')
        this.$('.topic-like').off('click.topic-like')
      },

      // Overrides

      @computed()
      expandPinned() {
        const pinned = this.get('topic.pinned');
        if (!pinned) {return this.get('showExcerpt')}
        if (this.get('controller.expandGloballyPinned') && this.get('topic.pinned_globally')) {return true;}
        if (this.get('controller.expandAllPinned')) {return true;}
        return false;
      },

      // Display objects

      @computed()
      posterNames() {
        let posters = this.get('topic.posters')
        let posterNames = ''
        posters.forEach((poster, i) => {
          let name = poster.user.name ? poster.user.name : poster.user.username
          posterNames += '<a href="' + poster.user.path + '" data-user-card="' + poster.user.username + '" + class="' + poster.extras + '">' + name + '</a>'
          if (i === posters.length - 2) {
            posterNames += '<span> & </span>'
          } else if (i != posters.length - 1) {
            posterNames += '<span>, </span>'
          }
        })
        return posterNames
      },

      @computed('topic.thumbnails')
      thumbnails(){
        return this.get('topic.thumbnails') || this.get('defaultThumbnail')
      },

      @computed()
      defaultThumbnail(){
        let topicCat = this.get('topic.category'),
            catThumb = topicCat ? topicCat.topic_list_default_thumbnail : false,
            defaultThumbnail = catThumb || Discourse.SiteSettings.topic_list_default_thumbnail;
        return defaultThumbnail ? defaultThumbnail : false
      },

      _sizeThumbnails() {
        this.$('.topic-thumbnail img').load(function(){
          $(this).css({
            'width': $(this)[0].naturalWidth
          })
        })
      },

      @observes('thumbnails')
      _rerenderOnThumbnailChange() {
        Ember.run.scheduleOnce('afterRender', this, () => {
          this._rearrangeDOM()
        })
      },

      @computed('likeDifference')
      topicActions() {
        let actions = []
        if (this.get('topic.topic_post_can_like') || !this.get('currentUser') ||
            Discourse.SiteSettings.topic_list_show_like_on_current_users_posts) {
          actions.push(this._likeButton())
        }
        if (this.get('canBookmark')) {
          actions.push(this._bookmarkButton())
          Ember.run.scheduleOnce('afterRender', this, () => {
            let $bookmarkStatus = this.$('.topic-statuses .op-bookmark')
            if ($bookmarkStatus) {
              $bookmarkStatus.hide()
            }
          })
        }
        return actions
      },

      likeCount() {
        let likeDifference = this.get('likeDifference'),
            count = (likeDifference == null ? this.get('topic.topic_post_like_count') : likeDifference) || 0;
        return count
      },

      @computed('likeDifference')
      likeCountDisplay() {
        let count = this.likeCount(),
            message = count === 1 ? "post.has_likes.one" : "post.has_likes.other";
        return count > 0 ? I18n.t(message, { count }) : false
      },

      @computed('hasLiked')
      hasLikedDisplay() {
        let hasLiked = this.get('hasLiked')
        return hasLiked == null ? this.get('topic.topic_post_liked') : hasLiked
      },

      changeLikeCount(change) {
        let count = this.likeCount(),
            newCount = count + (change || 0);
        this.set('hasLiked', Boolean(change > 0))
        this.set('likeDifference', newCount)
        this._likeRerender()
      },

      _likeRerender(){
        this.rerenderBuffer()
        Ember.run.scheduleOnce('afterRender', this, () => {
          this._rearrangeDOM()
          this._setupActions()
        })
      },

      _likeButton() {
        var classes = "topic-like",
            disabled = false;

        if (Discourse.SiteSettings.topic_list_show_like_on_current_users_posts) {
          disabled = this.get('topic.topic_post_is_current_users')
        }

        if (this.get('hasLikedDisplay')) {
          classes += ' has-like'
          let unlikeDisabled = this.get('topic.topic_post_can_unlike') ? false : this.get('likeDifference') == null
          disabled = disabled ? true : unlikeDisabled
        }

        return { class: classes, title: 'post.controls.like', icon: 'heart', disabled: disabled}
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

      // Action toggles and server methods

      toggleBookmark($bookmark, postId) {
        this.sendBookmark(postId, !$bookmark.hasClass('bookmarked'))
        $bookmark.toggleClass('bookmarked')
      },

      toggleLike($like, postId) {
        if (this.get('hasLikedDisplay')) {
          this.removeLike(postId)
          this.changeLikeCount(-1)
        } else {
          const scale = [1.0, 1.5];
          return new Ember.RSVP.Promise(resolve => {
            animateHeart($like, scale[0], scale[1], () => {
              animateHeart($like, scale[1], scale[0], () => {
                this.addLike(postId);
                this.changeLikeCount(1)
                resolve();
              });
            });
          });
        }
      },

      addLike(postId) {
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

      removeLike(postId) {
        ajax("/post_actions/" + postId, {
          type: 'DELETE',
          data: {
            post_action_type_id: 2
          }
        }).catch(function(error) {
          popupAjaxError(error);
        });
      }
    })

  }
}
