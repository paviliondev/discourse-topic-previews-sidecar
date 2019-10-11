export default {
  setupComponent(attrs, component) {
    component.set('portfolioEnabled', Discourse.SiteSettings.topic_list_portfolio);
  }
}