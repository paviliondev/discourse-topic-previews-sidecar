export default Ember.Helper.helper(function(params) {
  const category = params[0];
  const topic = params[1];
  if (topic && !Discourse.SiteSettings.topic_list_featured_images_topic) {
    return false;
  }
  if (!category || Discourse.SiteSettings.topic_list_featured_images_category) {
    return Discourse.SiteSettings.topic_list_featured_images;
  } else {
    return category.topic_list_featured_images;
  }
});
