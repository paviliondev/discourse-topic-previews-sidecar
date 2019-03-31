
const listChoices = ['latest', 'new', 'unread', 'top', 'suggested', 'agenda', 'latest-mobile', 'new-mobile', 'unread-mobile', 'top-mobile', 'suggested-mobile', 'agenda-mobile'];
const filterChoices = ['suggested', 'suggested-mobile'];
const listSettings = ['tiles', 'thumbnail', 'excerpt', 'action', 'category_column'];

export default {
  setupComponent(args, component) {
    const category = args.category;

    if (!category.custom_fields) {
      category.custom_fields = {};
    };

    listSettings.forEach((s) => {
      if (typeof category.custom_fields[`topic_list_${s}`] !== 'string') {
        category.custom_fields[`topic_list_${s}`] = '';
      }
    });
    component.set('choices', listChoices);

    const filteredChoices = listChoices.filter(c => (filterChoices.indexOf(c) === -1));

    component.set('filteredChoices', filteredChoices);
  }
};
