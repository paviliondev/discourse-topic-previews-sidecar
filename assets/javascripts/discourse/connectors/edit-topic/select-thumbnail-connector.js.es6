export default {
  setupComponent(attrs, component) {
    let topic_id = this.get('model.id');
    let topic_title = this.get('model.title');
    let buffered = this.get('buffered');

    component.setProperties({
      topic_id,
      topic_title,
      buffered
    });
  }
}
