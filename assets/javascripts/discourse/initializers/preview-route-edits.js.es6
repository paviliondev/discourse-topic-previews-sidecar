import { featuredImagesEnabled } from '../lib/utilities';
import { ajax } from 'discourse/lib/ajax';
import { withPluginApi } from 'discourse/lib/plugin-api';

export default {
  name: 'sidebar-discovery-routes',
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
            if (result && result.topic_list && result.topic_list.featured_topics) {
              this.controllerFor('discovery/topics').set(
                'featuredTopics', result.topic_list.featured_topics
              );
            }
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
            if (result[1] && result[1].topic_list && result[1].topic_list.featured_topics) {
              this.controllerFor('discovery/topics').set(
                'featuredTopics', result[1].topic_list.featured_topics
              );
            }
            return result;
          })
        }
      });
    });
  }
};
