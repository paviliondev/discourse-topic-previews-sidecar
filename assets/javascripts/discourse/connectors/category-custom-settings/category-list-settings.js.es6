const listChoices = ['latest', 'new', 'unread', 'top', 'suggested', 'agenda', 'latest-mobile', 'new-mobile', 'unread-mobile', 'top-mobile', 'suggested-mobile', 'agenda-mobile'];
const filterChoices = ['suggested', 'suggested-mobile'];
const listSettings = ['tiles', 'thumbnail', 'excerpt', 'action'];

export default {

  setupComponent(args, component) {

    component.set('tokenSeparator', "|");

    const category = args.category;

    if (!category.custom_fields) {
      category.custom_fields = {};
    };

    listSettings.forEach((s) => {
      if (typeof category.custom_fields[`topic_list_${s}`] !== 'string') {
        category.custom_fields[`topic_list_${s}`] = '';
      }
      component.set(s, category.custom_fields[`topic_list_${s}`].toString().split(this.tokenSeparator));
    });

    component.set('choices', listChoices);

    const filteredChoices = listChoices.filter(c => (filterChoices.indexOf(c) === -1));

    component.set('filteredChoices', filteredChoices);
  },

  actions: {
    onChangeCategoryListSetting(type, value) {
      this.set(type, value);
      this.set(`category.custom_fields.topic_list_${type}`, value.join(this.tokenSeparator));
    }
  }
};
