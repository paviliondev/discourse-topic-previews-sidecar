import UserTopicListRoute from "discourse/routes/user-topic-list";
import UserAction from "discourse/models/user-action";

export default UserTopicListRoute.extend({
  userActionType: UserAction.TYPES.topics,

  model() {

    let filter_type = Discourse.SiteSettings.topic_list_portfolio_filter_type;
    const filter_parameter = Discourse.SiteSettings.topic_list_portfolio_filter_parameter;

    if (filter_type == 'tag') {
      filter_type = 'tags'
    }

    return this.store.findFiltered("topicList", {
      filter: "topics/created-by/" + this.modelFor("user").get("username_lower"),
      params: {[filter_type]: filter_parameter}
      })
  }
});
