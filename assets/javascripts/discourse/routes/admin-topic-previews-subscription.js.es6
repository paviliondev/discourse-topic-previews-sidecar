import TopicPreviewsSubscription from "../models/topic-previews-subscription";
import DiscourseRoute from "discourse/routes/discourse";

export default DiscourseRoute.extend({
  model() {
    return TopicPreviewsSubscription.status();
  },

  setupController(controller, model) {
    controller.set("model", model);
    controller.setup();
  },

  actions: {
    authorize() {
      TopicPreviewsSubscription.authorize();
    },
  },
});
