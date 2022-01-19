export default {
  resource: "admin",
  map() {
    this.route(
      "adminTopicPreviews",
      { path: "/topic-previews", resetNamespace: true },
      function () {
        this.route("adminTopicPreviewsSubscription", {
          path: "/subscription",
          resetNamespace: true,
        });

        this.route("adminTopicPreviewsNotices", {
          path: "/notices",
          resetNamespace: true,
        });
      }
    );
  },
};


