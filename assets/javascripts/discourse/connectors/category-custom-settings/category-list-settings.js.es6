
const listChoices = ['latest', 'new', 'unread', 'top', 'suggested', 'agenda', 'latest-mobile', 'new-mobile', 'unread-mobile', 'top-mobile', 'suggested-mobile', 'agenda-mobile'];
const listSettings = ['tiles', 'thumbnail', 'excerpt', 'action', 'category_badge_move'];

export default {
  setupComponent(args, component) {
    const category = args.category;

    if (!category.custom_fields) {
      category.custom_fields = {};
    }

    listSettings.forEach((s) => {
      if (typeof args.category.custom_fields[`topic_list_${s}`] !== 'string') {
        args.category.custom_fields[`topic_list_${s}`] = '';
      }
    });
    component.set('choices', listChoices);
  }
};
