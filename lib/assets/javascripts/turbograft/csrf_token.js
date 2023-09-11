/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
window.CSRFToken = class CSRFToken {
  static get(doc) {
    if (doc == null) { doc = document; }
    const tag = doc.querySelector('meta[name="csrf-token"]');

    const object = {
      node: tag
    };

    if (tag) {
      object.token = tag.getAttribute('content');
    }

    return object;
  }

  static update(latest) {
    const current = this.get();
    if ((current.token != null) && (latest != null) && (current.token !== latest)) {
      return current.node.setAttribute('content', latest);
    }
  }
};
