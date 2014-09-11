(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
window.Page = function(setup) {
  var initModules;
  return initModules = setup || (function() {
    return {};
  });
};

Page.visit = function(url, opts) {
  if (opts == null) {
    opts = {};
  }
  if (opts.reload) {
    return window.location = url;
  } else {
    return Turbolinks.visit(url);
  }
};

Page.refresh = function(options, callback) {
  var newUrl, paramString;
  if (options == null) {
    options = {};
  }
  newUrl = options.url ? options.url : options.queryParams ? (paramString = $.param(options.queryParams), paramString ? paramString = "?" + paramString : void 0, location.pathname + paramString) : location.href;
  if (options.response) {
    return Turbolinks.loadPage(null, options.response, true, callback, options.onlyKeys || []);
  } else {
    return Turbolinks.visit(newUrl, true, options.onlyKeys || [], function() {
      return typeof callback === "function" ? callback() : void 0;
    });
  }
};

Page.onRefresh = function(instance, nodeOrCallback, callback) {
  var key, node, previousInstance;
  if (!callback) {
    callback = nodeOrCallback;
  } else {
    node = nodeOrCallback;
  }
  if (!node) {
    return;
  }
  key = Bindings.contextKey(node, instance);
  if (previousInstance = previousContext[key]) {
    reapplyQueue.push([previousInstance, callback]);
  }
  return previousContext[key] = instance;
};

Page.pushState = function(path) {
  return window.history.pushState({
    turbolinks: true,
    url: path
  }, null, path);
};

Page.replaceState = function(path) {
  return window.history.replaceState({
    turbolinks: true,
    url: path
  }, null, path);
};

Page.open = function() {
  return window.open.apply(window, arguments);
};



},{}],2:[function(require,module,exports){
var CSRFToken, Click, ComponentUrl, Link, browserCompatibleDocumentParser, browserIsntBuggy, browserSupportsCustomEvents, browserSupportsPushState, browserSupportsTurbolinks, bypassOnLoadPopstate, cacheCurrentPage, cacheSize, changePage, constrainPageCacheTo, createDocument, currentState, deleteRefreshNeverNodes, enableTransitionCache, executeScriptTag, executeScriptTags, extractTitleAndBody, fetch, fetchHistory, fetchReplacement, historyStateIsDefined, initializeTurbolinks, installDocumentReadyPageEventTriggers, installHistoryChangeHandler, installJqueryAjaxSuccessPageUpdateTrigger, loadPage, loadedAssets, pageCache, pageChangePrevented, pagesCached, popCookie, processResponse, recallScrollPosition, referer, reflectNewUrl, reflectRedirectedUrl, refreshNodesWithKeys, rememberCurrentState, rememberCurrentUrl, rememberReferer, removeNoscriptTags, requestMethodIsSafe, resetScrollPosition, transitionCacheEnabled, transitionCacheFor, triggerEvent, visit, xhr, _ref,
  __slice = [].slice,
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

pageCache = {};

cacheSize = 10;

transitionCacheEnabled = false;

currentState = null;

loadedAssets = null;

referer = null;

createDocument = null;

xhr = null;

fetch = function(url, partialReplace, replaceContents, callback) {
  var cachedPage;
  if (partialReplace == null) {
    partialReplace = false;
  }
  if (replaceContents == null) {
    replaceContents = [];
  }
  url = new ComponentUrl(url);
  rememberReferer();
  if (transitionCacheEnabled) {
    cacheCurrentPage();
  }
  reflectNewUrl(url);
  if (transitionCacheEnabled && (cachedPage = transitionCacheFor(url.absolute))) {
    fetchHistory(cachedPage);
    return fetchReplacement(url, partialReplace, null, replaceContents);
  } else {
    return fetchReplacement(url, partialReplace, function() {
      if (!replaceContents.length) {
        resetScrollPosition();
      }
      return typeof callback === "function" ? callback() : void 0;
    }, replaceContents);
  }
};

transitionCacheFor = function(url) {
  var cachedPage;
  cachedPage = pageCache[url];
  if (cachedPage && !cachedPage.transitionCacheDisabled) {
    return cachedPage;
  }
};

enableTransitionCache = function(enable) {
  if (enable == null) {
    enable = true;
  }
  return transitionCacheEnabled = enable;
};

fetchReplacement = function(url, partialReplace, onLoadFunction, replaceContents) {
  triggerEvent('page:fetch', {
    url: url.absolute
  });
  if (xhr != null) {
    xhr.abort();
  }
  xhr = new XMLHttpRequest;
  xhr.open('GET', url.withoutHashForIE10compatibility(), true);
  xhr.setRequestHeader('Accept', 'text/html, application/xhtml+xml, application/xml');
  xhr.setRequestHeader('X-XHR-Referer', referer);
  xhr.onload = function() {
    return loadPage(url, xhr, partialReplace, onLoadFunction, replaceContents);
  };
  xhr.onloadend = function() {
    return xhr = null;
  };
  xhr.onerror = function() {
    return document.location.href = url.absolute;
  };
  return xhr.send();
};

loadPage = function(url, xhr, partialReplace, onLoadFunction, replaceContents) {
  var doc, nodes;
  if (partialReplace == null) {
    partialReplace = false;
  }
  if (onLoadFunction == null) {
    onLoadFunction = (function() {});
  }
  if (replaceContents == null) {
    replaceContents = [];
  }
  triggerEvent('page:receive');
  if (doc = processResponse(xhr, partialReplace)) {
    nodes = changePage.apply(null, __slice.call(extractTitleAndBody(doc)).concat([partialReplace], [replaceContents]));
    reflectRedirectedUrl(xhr);
    triggerEvent('page:load', nodes);
    return typeof onLoadFunction === "function" ? onLoadFunction() : void 0;
  } else {
    return document.location.href = url.absolute;
  }
};

fetchHistory = function(cachedPage) {
  if (xhr != null) {
    xhr.abort();
  }
  changePage(cachedPage.title, cachedPage.body, false);
  recallScrollPosition(cachedPage);
  return triggerEvent('page:restore');
};

cacheCurrentPage = function() {
  var currentStateUrl;
  currentStateUrl = new ComponentUrl(currentState.url);
  pageCache[currentStateUrl.absolute] = {
    url: currentStateUrl.relative,
    body: document.body,
    title: document.title,
    positionY: window.pageYOffset,
    positionX: window.pageXOffset,
    cachedAt: new Date().getTime(),
    transitionCacheDisabled: document.querySelector('[data-no-transition-cache]') != null
  };
  return constrainPageCacheTo(cacheSize);
};

pagesCached = function(size) {
  if (size == null) {
    size = cacheSize;
  }
  if (/^[\d]+$/.test(size)) {
    return cacheSize = parseInt(size);
  }
};

constrainPageCacheTo = function(limit) {
  var cacheTimesRecentFirst, key, pageCacheKeys, _i, _len, _results;
  pageCacheKeys = Object.keys(pageCache);
  cacheTimesRecentFirst = pageCacheKeys.map(function(url) {
    return pageCache[url].cachedAt;
  }).sort(function(a, b) {
    return b - a;
  });
  _results = [];
  for (_i = 0, _len = pageCacheKeys.length; _i < _len; _i++) {
    key = pageCacheKeys[_i];
    if (!(pageCache[key].cachedAt <= cacheTimesRecentFirst[limit])) {
      continue;
    }
    triggerEvent('page:expire', pageCache[key]);
    _results.push(delete pageCache[key]);
  }
  return _results;
};

changePage = function(title, body, csrfToken, runScripts, partialReplace, replaceContents) {
  if (replaceContents == null) {
    replaceContents = [];
  }
  if (title) {
    document.title = title;
  }
  if (replaceContents.length) {
    return refreshNodesWithKeys(replaceContents, body);
  }
  if (partialReplace) {
    deleteRefreshNeverNodes(body);
  }
  triggerEvent('page:before-replace');
  document.documentElement.replaceChild(body, document.body);
  if (csrfToken != null) {
    CSRFToken.update(csrfToken);
  }
  if (runScripts) {
    executeScriptTags();
  }
  currentState = window.history.state;
  triggerEvent('page:change');
  triggerEvent('page:update');
};

deleteRefreshNeverNodes = function(body) {
  var node, _i, _len, _ref, _results;
  _ref = body.querySelectorAll('[refresh-never]');
  _results = [];
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    node = _ref[_i];
    _results.push(node.parentNode.removeChild(node));
  }
  return _results;
};

refreshNodesWithKeys = function(keys, body) {
  var allNodesToBeRefreshed, existingNode, key, newNode, node, nodeId, parentIsRefreshing, refreshedNodes, _i, _j, _k, _l, _len, _len1, _len2, _len3, _ref, _ref1;
  allNodesToBeRefreshed = [];
  _ref = document.querySelectorAll("[refresh-always]");
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    node = _ref[_i];
    allNodesToBeRefreshed.push(node);
  }
  for (_j = 0, _len1 = keys.length; _j < _len1; _j++) {
    key = keys[_j];
    _ref1 = document.querySelectorAll("[refresh=" + key + "]");
    for (_k = 0, _len2 = _ref1.length; _k < _len2; _k++) {
      node = _ref1[_k];
      allNodesToBeRefreshed.push(node);
    }
  }
  triggerEvent('page:before-partial-replace', allNodesToBeRefreshed);
  parentIsRefreshing = function(node) {
    var potentialParent, _l, _len3;
    for (_l = 0, _len3 = allNodesToBeRefreshed.length; _l < _len3; _l++) {
      potentialParent = allNodesToBeRefreshed[_l];
      if (node !== potentialParent) {
        if (potentialParent.contains(node)) {
          return true;
        }
      }
    }
    return false;
  };
  refreshedNodes = [];
  for (_l = 0, _len3 = allNodesToBeRefreshed.length; _l < _len3; _l++) {
    existingNode = allNodesToBeRefreshed[_l];
    if (parentIsRefreshing(existingNode)) {
      continue;
    }
    if (!(nodeId = existingNode.getAttribute('id'))) {
      throw new Error("Turbolinks refresh: Refresh key elements must have an id.");
    }
    if (newNode = body.querySelector("#" + nodeId)) {
      existingNode.parentNode.replaceChild(newNode, existingNode);
      if (newNode.nodeName === 'SCRIPT') {
        executeScriptTag(newNode);
      } else {
        refreshedNodes.push(newNode);
      }
    } else if (existingNode.getAttribute("refresh-always") === null) {
      existingNode.parentNode.removeChild(existingNode);
    }
  }
  return refreshedNodes;
};

executeScriptTags = function() {
  var script, scripts, _i, _len, _ref;
  scripts = Array.prototype.slice.call(document.body.querySelectorAll('script:not([data-turbolinks-eval="false"])'));
  for (_i = 0, _len = scripts.length; _i < _len; _i++) {
    script = scripts[_i];
    if ((_ref = script.type) === '' || _ref === 'text/javascript') {
      executeScriptTag(script);
    }
  }
};

executeScriptTag = function(script) {
  var attr, copy, nextSibling, parentNode, _i, _len, _ref;
  copy = document.createElement('script');
  _ref = script.attributes;
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    attr = _ref[_i];
    copy.setAttribute(attr.name, attr.value);
  }
  copy.appendChild(document.createTextNode(script.innerHTML));
  parentNode = script.parentNode, nextSibling = script.nextSibling;
  parentNode.removeChild(script);
  return parentNode.insertBefore(copy, nextSibling);
};

removeNoscriptTags = function(node) {
  node.innerHTML = node.innerHTML.replace(/<noscript[\S\s]*?<\/noscript>/ig, '');
  return node;
};

reflectNewUrl = function(url) {
  if ((url = new ComponentUrl(url)).absolute !== referer) {
    return window.history.pushState({
      turbolinks: true,
      url: url.absolute
    }, '', url.absolute);
  }
};

reflectRedirectedUrl = function(xhr) {
  var location, preservedHash;
  if (location = xhr.getResponseHeader('X-XHR-Redirected-To')) {
    location = new ComponentUrl(location);
    preservedHash = location.hasNoHash() ? document.location.hash : '';
    return window.history.replaceState(currentState, '', location.href + preservedHash);
  }
};

rememberReferer = function() {
  return referer = document.location.href;
};

rememberCurrentUrl = function() {
  return window.history.replaceState({
    turbolinks: true,
    url: document.location.href
  }, '', document.location.href);
};

rememberCurrentState = function() {
  return currentState = window.history.state;
};

recallScrollPosition = function(page) {
  return window.scrollTo(page.positionX, page.positionY);
};

resetScrollPosition = function() {
  if (document.location.hash) {
    return document.location.href = document.location.href;
  } else {
    return window.scrollTo(0, 0);
  }
};

popCookie = function(name) {
  var value, _ref;
  value = ((_ref = document.cookie.match(new RegExp(name + "=(\\w+)"))) != null ? _ref[1].toUpperCase() : void 0) || '';
  document.cookie = name + '=; expires=Thu, 01-Jan-70 00:00:01 GMT; path=/';
  return value;
};

triggerEvent = function(name, data) {
  var event;
  event = document.createEvent('Events');
  if (data) {
    event.data = data;
  }
  event.initEvent(name, true, true);
  return document.dispatchEvent(event);
};

pageChangePrevented = function() {
  return !triggerEvent('page:before-change');
};

processResponse = function(xhr, partial) {
  var assetsChanged, changed, clientOrServerError, doc, extractTrackAssets, intersection, validContent;
  if (partial == null) {
    partial = false;
  }
  clientOrServerError = function() {
    var _ref;
    if (xhr.status === 422) {
      return false;
    }
    return (400 <= (_ref = xhr.status) && _ref < 600);
  };
  validContent = function() {
    return xhr.getResponseHeader('Content-Type').match(/^(?:text\/html|application\/xhtml\+xml|application\/xml)(?:;|$)/);
  };
  extractTrackAssets = function(doc) {
    var node, _i, _len, _ref, _results;
    _ref = doc.head.childNodes;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      node = _ref[_i];
      if ((typeof node.getAttribute === "function" ? node.getAttribute('data-turbolinks-track') : void 0) != null) {
        _results.push(node.getAttribute('src') || node.getAttribute('href'));
      }
    }
    return _results;
  };
  assetsChanged = function(doc) {
    var fetchedAssets;
    loadedAssets || (loadedAssets = extractTrackAssets(document));
    fetchedAssets = extractTrackAssets(doc);
    return fetchedAssets.length !== loadedAssets.length || intersection(fetchedAssets, loadedAssets).length !== loadedAssets.length;
  };
  intersection = function(a, b) {
    var value, _i, _len, _ref, _results;
    if (a.length > b.length) {
      _ref = [b, a], a = _ref[0], b = _ref[1];
    }
    _results = [];
    for (_i = 0, _len = a.length; _i < _len; _i++) {
      value = a[_i];
      if (__indexOf.call(b, value) >= 0) {
        _results.push(value);
      }
    }
    return _results;
  };
  if (!clientOrServerError() && validContent()) {
    doc = createDocument(xhr.responseText);
    changed = assetsChanged(doc);
    if (doc && (!changed || partial)) {
      return doc;
    }
  }
};

extractTitleAndBody = function(doc) {
  var title;
  title = doc.querySelector('title');
  return [title != null ? title.textContent : void 0, removeNoscriptTags(doc.body), CSRFToken.get(doc).token, 'runScripts'];
};

CSRFToken = {
  get: function(doc) {
    var tag;
    if (doc == null) {
      doc = document;
    }
    return {
      node: tag = doc.querySelector('meta[name="csrf-token"]'),
      token: tag != null ? typeof tag.getAttribute === "function" ? tag.getAttribute('content') : void 0 : void 0
    };
  },
  update: function(latest) {
    var current;
    current = this.get();
    if ((current.token != null) && (latest != null) && current.token !== latest) {
      return current.node.setAttribute('content', latest);
    }
  }
};

browserCompatibleDocumentParser = function() {
  var createDocumentUsingDOM, createDocumentUsingParser, createDocumentUsingWrite, e, testDoc, _ref;
  createDocumentUsingParser = function(html) {
    return (new DOMParser).parseFromString(html, 'text/html');
  };
  createDocumentUsingDOM = function(html) {
    var doc;
    doc = document.implementation.createHTMLDocument('');
    doc.documentElement.innerHTML = html;
    return doc;
  };
  createDocumentUsingWrite = function(html) {
    var doc;
    doc = document.implementation.createHTMLDocument('');
    doc.open('replace');
    doc.write(html);
    doc.close();
    return doc;
  };
  try {
    if (window.DOMParser) {
      testDoc = createDocumentUsingParser('<html><body><p>test');
      return createDocumentUsingParser;
    }
  } catch (_error) {
    e = _error;
    testDoc = createDocumentUsingDOM('<html><body><p>test');
    return createDocumentUsingDOM;
  } finally {
    if ((testDoc != null ? (_ref = testDoc.body) != null ? _ref.childNodes.length : void 0 : void 0) !== 1) {
      return createDocumentUsingWrite;
    }
  }
};

ComponentUrl = (function() {
  function ComponentUrl(original) {
    this.original = original != null ? original : document.location.href;
    if (this.original.constructor === ComponentUrl) {
      return this.original;
    }
    this._parse();
  }

  ComponentUrl.prototype.withoutHash = function() {
    return this.href.replace(this.hash, '');
  };

  ComponentUrl.prototype.withoutHashForIE10compatibility = function() {
    return this.withoutHash();
  };

  ComponentUrl.prototype.hasNoHash = function() {
    return this.hash.length === 0;
  };

  ComponentUrl.prototype._parse = function() {
    var _ref;
    (this.link != null ? this.link : this.link = document.createElement('a')).href = this.original;
    _ref = this.link, this.href = _ref.href, this.protocol = _ref.protocol, this.host = _ref.host, this.hostname = _ref.hostname, this.port = _ref.port, this.pathname = _ref.pathname, this.search = _ref.search, this.hash = _ref.hash;
    this.origin = [this.protocol, '//', this.hostname].join('');
    if (this.port.length !== 0) {
      this.origin += ":" + this.port;
    }
    this.relative = [this.pathname, this.search, this.hash].join('');
    return this.absolute = this.href;
  };

  return ComponentUrl;

})();

Link = (function(_super) {
  __extends(Link, _super);

  Link.HTML_EXTENSIONS = ['html'];

  Link.allowExtensions = function() {
    var extension, extensions, _i, _len;
    extensions = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    for (_i = 0, _len = extensions.length; _i < _len; _i++) {
      extension = extensions[_i];
      Link.HTML_EXTENSIONS.push(extension);
    }
    return Link.HTML_EXTENSIONS;
  };

  function Link(link) {
    this.link = link;
    if (this.link.constructor === Link) {
      return this.link;
    }
    this.original = this.link.href;
    Link.__super__.constructor.apply(this, arguments);
  }

  Link.prototype.shouldIgnore = function() {
    return this._crossOrigin() || this._anchored() || this._nonHtml() || this._optOut() || this._target();
  };

  Link.prototype._crossOrigin = function() {
    return this.origin !== (new ComponentUrl).origin;
  };

  Link.prototype._anchored = function() {
    var current;
    return ((this.hash && this.withoutHash()) === (current = new ComponentUrl).withoutHash()) || (this.href === current.href + '#');
  };

  Link.prototype._nonHtml = function() {
    return this.pathname.match(/\.[a-z]+$/g) && !this.pathname.match(new RegExp("\\.(?:" + (Link.HTML_EXTENSIONS.join('|')) + ")?$", 'g'));
  };

  Link.prototype._optOut = function() {
    var ignore, link;
    link = this.link;
    while (!(ignore || link === document)) {
      ignore = link.getAttribute('data-no-turbolink') != null;
      link = link.parentNode;
    }
    return ignore;
  };

  Link.prototype._target = function() {
    return this.link.target.length !== 0;
  };

  return Link;

})(ComponentUrl);

Click = (function() {
  Click.installHandlerLast = function(event) {
    if (!event.defaultPrevented) {
      document.removeEventListener('click', Click.handle, false);
      return document.addEventListener('click', Click.handle, false);
    }
  };

  Click.handle = function(event) {
    return new Click(event);
  };

  function Click(event) {
    this.event = event;
    if (this.event.defaultPrevented) {
      return;
    }
    this._extractLink();
    if (this._validForTurbolinks()) {
      if (!pageChangePrevented()) {
        visit(this.link.href);
      }
      this.event.preventDefault();
    }
  }

  Click.prototype._extractLink = function() {
    var link;
    link = this.event.target;
    while (!(!link.parentNode || link.nodeName === 'A')) {
      link = link.parentNode;
    }
    if (link.nodeName === 'A' && link.href.length !== 0) {
      return this.link = new Link(link);
    }
  };

  Click.prototype._validForTurbolinks = function() {
    return (this.link != null) && !(this.link.shouldIgnore() || this._nonStandardClick());
  };

  Click.prototype._nonStandardClick = function() {
    return this.event.which > 1 || this.event.metaKey || this.event.ctrlKey || this.event.shiftKey || this.event.altKey;
  };

  return Click;

})();

bypassOnLoadPopstate = function(fn) {
  return setTimeout(fn, 500);
};

installDocumentReadyPageEventTriggers = function() {
  return document.addEventListener('DOMContentLoaded', (function() {
    triggerEvent('page:change');
    return triggerEvent('page:update');
  }), true);
};

installJqueryAjaxSuccessPageUpdateTrigger = function() {
  if (typeof jQuery !== 'undefined') {
    return jQuery(document).on('ajaxSuccess', function(event, xhr, settings) {
      if (!jQuery.trim(xhr.responseText)) {
        return;
      }
      return triggerEvent('page:update');
    });
  }
};

installHistoryChangeHandler = function(event) {
  var cachedPage, _ref;
  if ((_ref = event.state) != null ? _ref.turbolinks : void 0) {
    if (cachedPage = pageCache[(new ComponentUrl(event.state.url)).absolute]) {
      cacheCurrentPage();
      return fetchHistory(cachedPage);
    } else {
      return visit(event.target.location.href);
    }
  }
};

initializeTurbolinks = function() {
  rememberCurrentUrl();
  rememberCurrentState();
  createDocument = browserCompatibleDocumentParser();
  document.addEventListener('click', Click.installHandlerLast, true);
  return bypassOnLoadPopstate(function() {
    return window.addEventListener('popstate', installHistoryChangeHandler, false);
  });
};

historyStateIsDefined = window.history.state !== void 0 || navigator.userAgent.match(/Firefox\/2[6|7]/);

browserSupportsPushState = window.history && window.history.pushState && window.history.replaceState && historyStateIsDefined;

browserIsntBuggy = !navigator.userAgent.match(/CriOS\//);

requestMethodIsSafe = (_ref = popCookie('request_method')) === 'GET' || _ref === '';

browserSupportsTurbolinks = browserSupportsPushState && browserIsntBuggy && requestMethodIsSafe;

browserSupportsCustomEvents = document.addEventListener && document.createEvent;

if (browserSupportsCustomEvents) {
  installDocumentReadyPageEventTriggers();
  installJqueryAjaxSuccessPageUpdateTrigger();
}

if (browserSupportsTurbolinks) {
  visit = fetch;
  initializeTurbolinks();
} else {
  visit = function(url) {
    return document.location.href = url;
  };
}

this.Turbolinks = {
  visit: visit,
  pagesCached: pagesCached,
  enableTransitionCache: enableTransitionCache,
  allowLinkExtensions: Link.allowExtensions,
  supported: browserSupportsTurbolinks,
  loadPage: loadPage
};



},{}]},{},[2,1]);
