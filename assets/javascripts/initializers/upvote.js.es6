import { withPluginApi } from 'discourse/lib/plugin-api';

function  startVoting(api){

}

export default {
  name: 'upvote',
  initialize: function() {
    withPluginApi('0.1', api => startVoting(api));
  }
}