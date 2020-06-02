export default {
  setupComponent(attrs, component) {
    component.set('portfolioEnabled', component.siteSettings.topic_list_portfolio);
  }
}