export default Ember.Mixin.create({

    _settingEnabled(setting) {

        const routeEnabled = this.get('routeEnabled');
        if (routeEnabled) {
          return routeEnabled.indexOf(setting) > -1;
        }

        const filter = this._filter();
        const discoveryList = this.get('discoveryList');
        const suggestedList = this.get('suggestedList');
        const currentRoute = this.get('currentRoute');

        if (!discoveryList && !suggestedList && !(currentRoute.indexOf('userActivity') > -1)) return false;

        const category = this.get('category');
        const catSetting = category ? category.get(setting) : false;
        const siteSetting = Discourse.SiteSettings[setting] ? Discourse.SiteSettings[setting].toString() : false;
        const filterArr = filter ? filter.split('/') : [];
        const filterType = filterArr[filterArr.length - 1];
        const catEnabled = catSetting && catSetting.split('|').indexOf(filterType) > -1;
        const siteEnabled = siteSetting && siteSetting.split('|').indexOf(filterType) > -1;
        const siteDefaults = Discourse.SiteSettings.topic_list_set_category_defaults;
        const isTopic = (filterType == 'suggested');

        return isTopic ? siteEnabled : (category ? (catEnabled || siteDefaults && siteEnabled) : siteEnabled);
      },

      _filter() {

        let filter = this.get('parentView.model.filter');

        const currentRoute = this.get('currentRoute');
        if (currentRoute.indexOf('tag') > -1) filter = 'tags';
        if (currentRoute.indexOf('top') > -1) filter = 'top';
        if (currentRoute.indexOf('topic') > -1) filter = 'suggested';
        if (currentRoute == 'userActivity.portfolio') filter = 'activity-portfolio';
        if (currentRoute == 'userActivity.topics') filter = 'activity-topics';

        const mobile = this.get('site.mobileView');
        if (mobile) filter += '-mobile';

        return filter;
      }
})