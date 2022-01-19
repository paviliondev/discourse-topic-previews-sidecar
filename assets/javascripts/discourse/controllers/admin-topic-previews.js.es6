import Controller, { inject as controller } from "@ember/controller";
import { isPresent } from "@ember/utils";
import { A } from "@ember/array";

export default Controller.extend({
  adminTopicPreviewsNotices: controller(),

  unsubscribe() {
    this.messageBus.unsubscribe("/topic-previews/notices");
  },

  subscribe() {
    this.unsubscribe();
    this.messageBus.subscribe("/topic-previews/notices", (data) => {
      if (isPresent(data.active_notice_count)) {
        this.set("activeNoticeCount", data.active_notice_count);
        this.adminTopicPreviewsNotices.setProperties({
          notices: A(),
          page: 0,
          canLoadMore: true,
        });
        this.adminTopicPreviewsNotices.loadMoreNotices();
      }
    });
  },
});
