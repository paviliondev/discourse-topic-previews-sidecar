import TopicPreviewsNotice from "../models/topic-previews-notice";
import DiscourseRoute from "discourse/routes/discourse";
import { A } from "@ember/array";

export default DiscourseRoute.extend({
  model() {
    return TopicPreviewsNotice.list({ include_all: true });
  },

  setupController(controller, model) {
    controller.setProperties({
      notices: A(
        model.notices.map((notice) => TopicPreviewsNotice.create(notice))
      ),
    });
  },
});
