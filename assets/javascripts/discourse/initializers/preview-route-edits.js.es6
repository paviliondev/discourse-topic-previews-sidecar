import { featuredImagesEnabled } from '../lib/utilities';
import { ajax } from 'discourse/lib/ajax';
import { withPluginApi } from 'discourse/lib/plugin-api';
import PreloadStore from "preload-store";
import CategoryList from "discourse/models/category-list";
import TopicList from "discourse/models/topic-list";

export default {
  name: 'preview-route-edits',
  initialize(container){
    const site = container.lookup('site:main');

    if (site.mobileView) return;

    let discoveryTopicRoutes = [];
    let discoveryCategoryRoutes = [
      'Category',
      'ParentCategory',
      'CategoryNone',
      'CategoryWithID'
    ];
    let filters = site.get('filters');
    filters.push('top');
    filters.forEach(filter => {
      const filterCapitalized = filter.capitalize();
      discoveryTopicRoutes.push(filterCapitalized);
      discoveryCategoryRoutes.push(...[
        `${filterCapitalized}Category`,
        `${filterCapitalized}ParentCategory`,
        `${filterCapitalized}CategoryNone`
      ]);
    });

    site.get('periods').forEach(period => {
      const periodCapitalized = period.capitalize();
      discoveryTopicRoutes.push(`Top${periodCapitalized}`);
      discoveryCategoryRoutes.push(...[
        `Top${periodCapitalized}Category`,
        `Top${periodCapitalized}ParentCategory`,
        `Top${periodCapitalized}CategoryNone`
      ]);
    });

    discoveryTopicRoutes.forEach(function(route){
      var route = container.lookup(`route:discovery.${route}`);
      route.reopen({
        model(data, transition) {
          return this._super(data, transition).then((result) => {
            let featuredTopics = null;

            if (result && result.topic_list && result.topic_list.featured_topics) {
              featuredTopics = result.topic_list.featured_topics;
            }

            this.controllerFor('discovery').set('featuredTopics', featuredTopics);

            return result;
          })
        }
      });
    });

    discoveryCategoryRoutes.forEach(function(route){
      var route = container.lookup(`route:discovery.${route}`);
      route.reopen({
        afterModel(model, transition) {
          return this._super(model, transition).then((result) => {
            let featuredTopics = null;

            if (result[1] && result[1].topic_list && result[1].topic_list.featured_topics) {
              featuredTopics = result[1].topic_list.featured_topics;
            }

            this.controllerFor('discovery').set('featuredTopics', featuredTopics);

            return result;
          })
        }
      });
    });

    withPluginApi('0.8.12', api => {
      api.modifyClass(`route:discovery-categories`, {

        setFeaturedTopics(topicList) {
          let featuredTopics = null;

          if (topicList && topicList.topic_list && topicList.topic_list.featured_topics) {
            featuredTopics = topicList.topic_list.featured_topics;
          }

          this.controllerFor('discovery').set('featuredTopics', featuredTopics);
        },

        // unfortunately we have to override this whole method to extract the featured topics
        _findCategoriesAndTopics(filter) {
          return Ember.RSVP.hash({
            wrappedCategoriesList: PreloadStore.getAndRemove("categories_list"),
            topicsList: PreloadStore.getAndRemove(`topic_list_${filter}`)
          }).then(hash => {
            let { wrappedCategoriesList, topicsList } = hash;
            let categoriesList = wrappedCategoriesList &&
              wrappedCategoriesList.category_list;

            if (categoriesList && topicsList) {
              this.setFeaturedTopics(topicsList);

              return Ember.Object.create({
                categories: CategoryList.categoriesFrom(
                  this.store,
                  wrappedCategoriesList
                ),
                topics: TopicList.topicsFrom(this.store, topicsList),
                can_create_category: categoriesList.can_create_category,
                can_create_topic: categoriesList.can_create_topic,
                draft_key: categoriesList.draft_key,
                draft: categoriesList.draft,
                draft_sequence: categoriesList.draft_sequence
              });
            }
            // Otherwise, return the ajax result
            return ajax(`/categories_and_${filter}`).then(result => {
              this.setFeaturedTopics(result);

              return Ember.Object.create({
                categories: CategoryList.categoriesFrom(this.store, result),
                topics: TopicList.topicsFrom(this.store, result),
                can_create_category: result.category_list.can_create_category,
                can_create_topic: result.category_list.can_create_topic,
                draft_key: result.category_list.draft_key,
                draft: result.category_list.draft,
                draft_sequence: result.category_list.draft_sequence
              });
            });
          });
        }
      });
    });
  }
};
