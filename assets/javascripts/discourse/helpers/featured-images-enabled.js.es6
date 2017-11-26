export default Ember.Helper.helper(function(params) {
  const category = params[0];
  if (!category || Discourse.SiteSettings.topic_list_featured_images_category) {
    return Discourse.SiteSettings.topic_list_featured_images;
  } else {
    return category.topic_list_featured_images;
  }
});
