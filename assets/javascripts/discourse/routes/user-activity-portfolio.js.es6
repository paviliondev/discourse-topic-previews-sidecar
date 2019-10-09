import UserTopicListRoute from "discourse/routes/user-topic-list";
import UserAction from "discourse/models/user-action";

export default UserTopicListRoute.extend({
  userActionType: UserAction.TYPES.topics,

  model: function() {

    let filter = Discourse.SiteSettings.topic_list_activity_portfolio_filter;
    let filter_delimiter = filter.indexOf(':');
    let filter_type = filter.substring(0, filter_delimiter);
    let filter_parameter = filter.substring(filter_delimiter + 1);

    if (filter_type == "category") {
      return this.store.findFiltered("topicList", {
        filter: "topics/created-by/" + this.modelFor("user").get("username_lower"),
        params: {category: filter_parameter}
      })} else {
        return this.store.findFiltered("topicList", {
          filter: "topics/created-by/" + this.modelFor("user").get("username_lower"),
          params: {tags: filter_parameter}
      })};
  }
});
