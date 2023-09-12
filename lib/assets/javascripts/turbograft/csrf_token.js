window.CSRFToken = class CSRFToken {
  static get(doc) {
    if (!doc) { doc = document; }
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
      current.node.setAttribute('content', latest);
    }
  }
};
