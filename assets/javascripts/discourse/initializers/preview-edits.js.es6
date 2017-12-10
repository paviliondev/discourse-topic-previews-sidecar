import { testImageUrl, animateHeart } from '../lib/utilities';
import { addLike, sendBookmark, removeLike } from '../lib/actions';
import { withPluginApi } from 'discourse/lib/plugin-api';
import { default as computed, on, observes } from 'ember-addons/ember-computed-decorators';
import DiscourseURL from 'discourse/lib/url';

export default {
  name: 'preview-edits',
  initialize(container){

    if (!Discourse.SiteSettings.topic_list_previews_enabled) return;

    withPluginApi('0.8.12', (api) => {
      api.modifyClass('component:topic-list', {
        router: Ember.inject.service('-routing'),
        currentRoute: Ember.computed.alias('router.router.currentRouteName'),
        classNameBindings: ['showThumbnail', 'showExcerpt', 'showActions', 'socialStyle'],
        suggestedList: Ember.computed.equal('parentView.parentView.parentView.elementId', 'suggested-topics'),
        discoveryList: Ember.computed.equal('parentView._debugContainerKey', 'component:discovery-topics-list'),

        @on('init')
        setup() {
          const suggestedList = this.get('suggestedList');
          if (suggestedList) {
            const category = this.get('parentView.parentView.parentView.topic.category');
            this.set('category', category);
          }
        },

        @on('didInsertElement')
        @observes('currentRoute')
        setHideCategory() {
          const mobile = this.get('site.mobileView');
          if (!mobile && this.settingEnabled('topic_list_category_badge_move')) {
            this.set('hideCategory', true);
          }
        },

        @on("didInsertElement")
        @observes("socialStyle")
        setupListStyle() {
          if (!this.$()) {return;}
          this.$().parents('#list-area').toggleClass('social-style', this.get('socialStyle'));
        },

        @on('willDestroyElement')
        _tearDown() {
          this.$().parents('#list-area').removeClass('social-style');
        },

        filter() {
          let filter = this.get('parentView.model.filter');

          const currentRoute = this.get('currentRoute');
          if (currentRoute.indexOf('tags') > -1) filter = 'tags';

          const suggestedList = this.get('suggestedList');
          if (suggestedList) filter = 'suggested';

          const mobile = this.get('site.mobileView');
          if (mobile) filter += '-mobile';

          return filter;
        },

        settingEnabled(setting) {
          const filter = this.filter();
          const discoveryList = this.get('discoveryList');
          const suggestedList = this.get('suggestedList');

          if (!discoveryList && !suggestedList) return false;

          const category = this.get('category');
          const catSetting = category ? category.get(setting) : false;
          const siteSetting = Discourse.SiteSettings[setting] ? Discourse.SiteSettings[setting].toString() : false;
          const filterArr = filter ? filter.split('/') : [];
          const filterType = filterArr[filterArr.length - 1];

          const catEnabled = catSetting && catSetting.split('|').indexOf(filterType) > -1;
          const siteEnabled = siteSetting && siteSetting.split('|').indexOf(filterType) > -1;
          const siteDefaults = Discourse.SiteSettings.topic_list_set_category_defaults;

          return category ? (catEnabled || siteDefaults && siteEnabled) : siteEnabled;
        },

        @computed('currentRoute')
        socialStyle() {
          return this.settingEnabled('topic_list_social');
        },

        @computed('currentRoute')
        showThumbnail() {
          return this.settingEnabled('topic_list_thumbnail');
        },

        @computed('currentRoute')
        showExcerpt() {
          return this.settingEnabled('topic_list_excerpt');
        },

        @computed('currentRoute')
        showActions() {
          return this.settingEnabled('topic_list_action');
        },

        @computed('currentRoute')
        showCategoryBadge() {
          return this.settingEnabled('topic_list_category_badge_move');
        },

        @computed('currentRoute')
        skipHeader() {
          return this.get('socialStyle') || this.get('site.mobileView');
        },

        @computed('currentRoute')
        thumbnailFirstXRows() {
          return Discourse.SiteSettings.topic_list_thumbnail_first_x_rows;
        }
      });

      api.modifyClass('component:topic-list-item', {
        canBookmark: Ember.computed.bool('currentUser'),
        rerenderTriggers: ['bulkSelectEnabled', 'topic.pinned', 'likeDifference', 'topic.thumbnails'],
        socialStyle: Ember.computed.alias('parentView.socialStyle'),
        showThumbnail: Ember.computed.and('thumbnails', 'parentView.showThumbnail'),
        showExcerpt: Ember.computed.and('topic.excerpt', 'parentView.showExcerpt'),
        showActions: Ember.computed.alias('parentView.showActions'),
        showCategoryBadge: Ember.computed.alias('parentView.showCategoryBadge'),
        thumbnailFirstXRows: Ember.computed.alias('parentView.thumbnailFirstXRows'),
        category: Ember.computed.alias('parentView.category'),

        // Lifecyle logic

        @on('init')
        _setupProperties() {
          const topic = this.get('topic');
          const thumbnails = topic.get('thumbnails');
          const defaultThumbnail = this.get('defaultThumbnail');
          if (thumbnails) {
            testImageUrl(thumbnails, (imageLoaded) => {
              if (!imageLoaded) {
                Ember.run.scheduleOnce('afterRender', this, () => {
                  if (defaultThumbnail) {
                    const $thumbnail = this.$('img.thumbnail');
                    if ($thumbnail) $thumbnail.attr('src', defaultThumbnail);
                  } else {
                    const $container = this.$('.topic-thumbnail');
                    if ($container) $container.hide();
                  }
                });
              }
            });
          } else if (defaultThumbnail && Discourse.SiteSettings.topic_list_default_thumbnail_fallback) {
            this.set('thumbnails', defaultThumbnail);
          }
        },

        @on('didInsertElement')
        _setupDOM() {
          const topic = this.get('topic');
          if (topic.get('thumbnails') && this.get('thumbnailFirstXRows') && (this.$().index() > this.get('thumbnailFirstXRows'))) {
            this.set('showThumbnail', false);
          }

          this._afterRender();
        },

        @observes('thumbnails')
        _afterRender() {
          Ember.run.scheduleOnce('afterRender', this, () => {
            this._setupTitleCSS();
            if (this.get('showThumbnail') && this.get('socialStyle')) {
              this._sizeThumbnails();
            }
            if (this.get('showExcerpt')) {
              this._setupExcerptClick();
            }
            if (this.get('showActions')) {
              this._setupActions();
            }
          });
        },

        _setupTitleCSS() {
          this.$('.topic-title a.visited').closest('.topic-details').addClass('visited');
        },

        _setupExcerptClick() {
          this.$('.topic-excerpt').on('click.topic-excerpt', () => {
            let topic = this.get('topic'),
                url = '/t/' + topic.slug + '/' + topic.id;
            if (topic.topic_post_number) {
              url += '/' + topic.topic_post_number;
            }
            DiscourseURL.routeTo(url);
          });
        },

        _sizeThumbnails() {
          this.$('.topic-thumbnail img').load(function(){
            $(this).css({
              'width': $(this)[0].naturalWidth
            });
          });
        },

        _setupActions() {
          let postId = this.get('topic.topic_post_id'),
              $bookmark = this.$('.topic-bookmark'),
              $like = this.$('.topic-like');

          $bookmark.on('click.topic-bookmark', () => {
            this.toggleBookmark($bookmark, postId);
          });

          $like.on('click.topic-like', () => {
            if (this.get('currentUser')) {
              this.toggleLike($like, postId);
            } else {
              const controller = container.lookup('controller:application');
              controller.send('showLogin');
            }
          });
        },

        @on('willDestroyElement')
        _tearDown() {
          this.$('.topic-excerpt').off('click.topic-excerpt');
          this.$('.topic-bookmark').off('click.topic-bookmark');
          this.$('.topic-like').off('click.topic-like');
        },

        // Overrides

        @computed()
        expandPinned() {
          const pinned = this.get('topic.pinned');
          if (!pinned) {return this.get('showExcerpt');}
          if (this.get('controller.expandGloballyPinned') && this.get('topic.pinned_globally')) {return true;}
          if (this.get('controller.expandAllPinned')) {return true;}
          return false;
        },

        // Display objects

        @computed()
        posterNames() {
          let posters = this.get('topic.posters');
          let posterNames = '';
          posters.forEach((poster, i) => {
            let name = poster.user.name ? poster.user.name : poster.user.username;
            posterNames += '<a href="' + poster.user.path + '" data-user-card="' + poster.user.username + '" + class="' + poster.extras + '">' + name + '</a>';
            if (i === posters.length - 2) {
              posterNames += '<span> & </span>';
            } else if (i !== posters.length - 1) {
              posterNames += '<span>, </span>';
            }
          });
          return posterNames;
        },

        @computed('topic.thumbnails')
        thumbnails(){
          return this.get('topic.thumbnails');
        },

        @computed()
        defaultThumbnail(){
          let topicCat = this.get('topic.category'),
              catThumb = topicCat ? topicCat.topic_list_default_thumbnail : false,
              defaultThumbnail = catThumb || Discourse.SiteSettings.topic_list_default_thumbnail;
          return defaultThumbnail ? defaultThumbnail : false;
        },

        @computed('likeDifference')
        topicActions() {
          let actions = [];
          if (this.get('topic.topic_post_can_like') || !this.get('currentUser') ||
              Discourse.SiteSettings.topic_list_show_like_on_current_users_posts) {
            actions.push(this._likeButton());
          }
          if (this.get('canBookmark')) {
            actions.push(this._bookmarkButton());
            Ember.run.scheduleOnce('afterRender', this, () => {
              let $bookmarkStatus = this.$('.topic-statuses .op-bookmark');
              if ($bookmarkStatus) {
                $bookmarkStatus.hide();
              }
            });
          }
          return actions;
        },

        likeCount() {
          let likeDifference = this.get('likeDifference'),
              count = (likeDifference == null ? this.get('topic.topic_post_like_count') : likeDifference) || 0;
          return count;
        },

        @computed('likeDifference')
        likeCountDisplay() {
          let count = this.likeCount(),
              message = count === 1 ? "post.has_likes.one" : "post.has_likes.other";
          return count > 0 ? I18n.t(message, { count }) : false;
        },

        @computed('hasLiked')
        hasLikedDisplay() {
          let hasLiked = this.get('hasLiked');
          return hasLiked == null ? this.get('topic.topic_post_liked') : hasLiked;
        },

        changeLikeCount(change) {
          let count = this.likeCount(),
              newCount = count + (change || 0);
          this.set('hasLiked', Boolean(change > 0));
          this.set('likeDifference', newCount);
          this.rerenderBuffer();
          this._afterRender();
        },

        _likeButton() {
          var classes = "topic-like",
              disabled = false;

          if (Discourse.SiteSettings.topic_list_show_like_on_current_users_posts) {
            disabled = this.get('topic.topic_post_is_current_users');
          }

          if (this.get('hasLikedDisplay')) {
            classes += ' has-like';
            let unlikeDisabled = this.get('topic.topic_post_can_unlike') ? false : this.get('likeDifference') == null;
            disabled = disabled ? true : unlikeDisabled;
          }

          return { class: classes, title: 'post.controls.like', icon: 'heart', disabled: disabled};
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
          sendBookmark(postId, !$bookmark.hasClass('bookmarked'));
          $bookmark.toggleClass('bookmarked');
        },

        toggleLike($like, postId) {
          if (this.get('hasLikedDisplay')) {
            removeLike(postId);
            this.changeLikeCount(-1);
          } else {
            const scale = [1.0, 1.5];
            return new Ember.RSVP.Promise(resolve => {
              animateHeart($like, scale[0], scale[1], () => {
                animateHeart($like, scale[1], scale[0], () => {
                  addLike(postId);
                  this.changeLikeCount(1);
                  resolve();
                });
              });
            });
          }
        }
      });
    });
  }
};
