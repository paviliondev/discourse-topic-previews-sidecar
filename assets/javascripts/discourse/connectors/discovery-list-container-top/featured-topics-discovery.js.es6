import { getOwner } from 'discourse-common/lib/get-owner';

export default {
  setupComponent(attrs, component) {
    const controller = getOwner(this).lookup('controller:discovery/topics');
    controller.addObserver('featuredTopics', () => {
      if (this._state === 'destroying') return;
      const featuredTopics = controller.get('featuredTopics');
      component.set('featuredTopics', featuredTopics);
    });

    const categoriesController = getOwner(this).lookup('controller:discovery/categories');
    component.set('featuredTopics', categoriesController.get('featuredTopics'));

    categoriesController.addObserver('featuredTopics', () => {
      if (this._state === 'destroying') return;
      const featuredTopics = categoriesController.get('featuredTopics');
      component.set('featuredTopics', featuredTopics);
    });
  }
}
