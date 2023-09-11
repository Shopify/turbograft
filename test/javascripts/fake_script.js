/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
window.fakeScript = function(src) {
  let node;
  const listeners = [];
  return node = {
    'data-turbolinks-track': src,
    attributes: [{name: 'src', value: src}],
    isLoaded: false,
    src,
    nodeName: 'SCRIPT',

    appendChild() { return {}; },

    setAttribute(name, value) {
      if (name === 'src') {
        this.src = value;
      }
      return this.attributes.push({name, value});
    },

    addEventListener(eventName, listener) {
      if (eventName !== 'load') { return; }
      return listeners.push(listener);
    },

    fireLoaded() {
      for (var listener of Array.from(listeners)) { listener({type: 'load'}); }
      return new Promise(function(resolve) {
        node.isLoaded = true;
        return setTimeout(() => resolve(node));
      });
    },

    removeEventListener() { return {}; }
  };
};
