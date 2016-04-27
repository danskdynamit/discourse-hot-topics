import { createWidget } from 'discourse/widgets/widget';
import { h } from 'virtual-dom';

export default createWidget('voting-button', {
  tagName: 'div.voting-button',

  buildClasses(attrs, state) {
    return '';
  },
  
  defaultState() {
    return { expandedFirstPost: false, repliesBelow: [] };
  },

  html(attrs, state){
    var voteCount = this.attrs.like_count
    const extraState = { state: { repliesShown: !!state.repliesBelow.length } };
    var test = this.attach('post-menu', attrs, extraState)
    var upvoteTitle = I18n.t("upvote.upvote");
    return [voteCount, test];
  },

  click(){
    console.log(this);
    const post = this.model;
    const likeAction = post.get('likeAction');

    if (likeAction && likeAction.get('canToggle')) {
      return likeAction.togglePromise(post).then(result => this._warnIfClose(result));
    }
  }
});