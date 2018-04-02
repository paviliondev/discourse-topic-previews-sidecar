import { featuredImagesEnabled } from '../lib/utilities';

export default Ember.Helper.helper(function(params) {
  return featuredImagesEnabled(params[0], params[1]);
});
