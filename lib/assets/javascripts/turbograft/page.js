/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
if (!window.Page) { window.Page = {}; }

Page.visit = function(url, opts) {
  if (opts == null) { opts = {}; }
  if (opts.reload) {
    return window.location = url;
  } else {
    return Turbolinks.visit(url);
  }
};

Page.refresh = function(options, callback) {
  let xhr;
  if (options == null) { options = {}; }
  const newUrl = (() => {
    if (options.url) {
    return options.url;
  } else if (options.queryParams) {
    let paramString = $.param(options.queryParams);
    if (paramString) { paramString = `?${paramString}`; }
    return location.pathname + paramString;
  } else {
    return location.href;
  }
  })();

  const turboOptions = {
    partialReplace: true,
    exceptKeys: options.exceptKeys,
    onlyKeys: options.onlyKeys,
    updatePushState: options.updatePushState,
    callback
  };

  if ((xhr = options.response)) {
    return Turbolinks.loadPage(null, xhr, turboOptions);
  } else {
    return Turbolinks.visit(newUrl, turboOptions);
  }
};

Page.open = function() {
  return window.open(...arguments);
};

// Providing hooks for objects to set up destructors:
let onReplaceCallbacks = [];

// e.g., Page.onReplace(node, unbindListenersFnc)
// unbindListenersFnc will be called if the node in question is partially replaced
// or if a full replace occurs.  It will be called only once
Page.onReplace = function(node, callback) {
  if (!node || !callback) { throw new Error("Page.onReplace: Node and callback must both be specified"); }
  if (!isFunction(callback)) { throw new Error("Page.onReplace: Callback must be a function"); }
  return onReplaceCallbacks.push({node, callback});
};

// option C from http://jsperf.com/alternative-isfunction-implementations
var isFunction = object => !!(object && object.constructor && object.call && object.apply);

// roughly based on http://davidwalsh.name/check-parent-node (note, OP is incorrect)
const contains = function(parentNode, childNode) {
  if (parentNode.contains) {
    return parentNode.contains(childNode);
  } else { // old browser compatability
    return !!((parentNode === childNode) || (parentNode.compareDocumentPosition(childNode) & Node.DOCUMENT_POSITION_CONTAINED_BY));
  }
};

document.addEventListener('page:before-partial-replace', function(event) {
  const replacedNodes = event.data;

  const unprocessedOnReplaceCallbacks = [];
  for (var entry of Array.from(onReplaceCallbacks)) {
    var fired = false;
    for (var replacedNode of Array.from(replacedNodes)) {
      if (contains(replacedNode, entry.node)) {
        entry.callback();
        fired = true;
        break;
      }
    }

    if (!fired) {
      unprocessedOnReplaceCallbacks.push(entry);
    }
  }

  return onReplaceCallbacks = unprocessedOnReplaceCallbacks;
});

document.addEventListener('page:before-replace', function(event) {
  for (var entry of Array.from(onReplaceCallbacks)) {
    entry.callback();
  }
  return onReplaceCallbacks = [];
});
