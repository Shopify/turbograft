(function() {
  var Response, TurboHead, activeDocument, browserSupportsCustomEvents, browserSupportsPushState, browserSupportsTurbolinks, historyStateIsDefined, installDocumentReadyPageEventTriggers, installJqueryAjaxSuccessPageUpdateTrigger, jQuery, popCookie, ref, removeNode, replaceNode, requestMethodIsSafe, xhr;

  Response = TurboGraft.Response;

  TurboHead = TurboGraft.TurboHead;

  jQuery = window.jQuery;

  xhr = null;

  activeDocument = document;

  installDocumentReadyPageEventTriggers = function() {
    return activeDocument.addEventListener('DOMContentLoaded', (function() {
      triggerEvent('page:change');
      return triggerEvent('page:update');
    }), true);
  };

  installJqueryAjaxSuccessPageUpdateTrigger = function() {
    if (typeof jQuery !== 'undefined') {
      return jQuery(activeDocument).on('ajaxSuccess', function(event, xhr, settings) {
        if (!jQuery.trim(xhr.responseText)) {
          return;
        }
        return triggerEvent('page:update');
      });
    }
  };

  historyStateIsDefined = window.history.state !== void 0 || navigator.userAgent.match(/Firefox\/2[6|7]/);

  browserSupportsPushState = window.history && window.history.pushState && window.history.replaceState && historyStateIsDefined;

  window.triggerEvent = function(name, data) {
    var event;
    event = activeDocument.createEvent('Events');
    if (data) {
      event.data = data;
    }
    event.initEvent(name, true, true);
    return activeDocument.dispatchEvent(event);
  };

  window.triggerEventFor = function(name, node, data) {
    var event;
    event = activeDocument.createEvent('Events');
    if (data) {
      event.data = data;
    }
    event.initEvent(name, true, true);
    return node.dispatchEvent(event);
  };

  popCookie = function(name) {
    var ref, value;
    value = ((ref = activeDocument.cookie.match(new RegExp(name + "=(\\w+)"))) != null ? ref[1].toUpperCase() : void 0) || '';
    activeDocument.cookie = name + '=; expires=Thu, 01-Jan-70 00:00:01 GMT; path=/';
    return value;
  };

  requestMethodIsSafe = (ref = popCookie('request_method')) === 'GET' || ref === '';

  browserSupportsTurbolinks = browserSupportsPushState && requestMethodIsSafe;

  browserSupportsCustomEvents = activeDocument.addEventListener && activeDocument.createEvent;

  if (browserSupportsCustomEvents) {
    installDocumentReadyPageEventTriggers();
    installJqueryAjaxSuccessPageUpdateTrigger();
  }

  replaceNode = function(newNode, oldNode) {
    var replacedNode;
    replacedNode = oldNode.parentNode.replaceChild(newNode, oldNode);
    return triggerEvent('page:after-node-removed', replacedNode);
  };

  removeNode = function(node) {
    var removedNode;
    removedNode = node.parentNode.removeChild(node);
    return triggerEvent('page:after-node-removed', removedNode);
  };

  /* TODO: triggerEvent should be accessible to all these guys
   * on some kind of eventbus
   * TODO: clean up everything above me ^
   * TODO: decide on the public API
   */
  window.Turbolinks = (function() {
    var anyAutofocusElement, bypassOnLoadPopstate, changePage, currentState, deleteRefreshNeverNodes, executeScriptTag, executeScriptTags, fetch, fetchReplacement, getNodesMatchingRefreshKeys, getNodesWithRefreshAlways, installHistoryChangeHandler, isPartialReplace, keepNodes, pageChangePrevented, persistStaticElements, recallScrollPosition, referer, reflectNewUrl, refreshAllExceptWithKeys, refreshNodes, rememberReferer, removeNoscriptTags, setAutofocusElement, updateBody;

    function Turbolinks() {}

    currentState = null;

    referer = null;

    fetch = function(url, options) {
      if (options == null) {
        options = {};
      }
      if (pageChangePrevented(url)) {
        return;
      }
      url = new ComponentUrl(url);
      rememberReferer();
      return fetchReplacement(url, options);
    };

    isPartialReplace = function(response, options) {
      var ref1, ref2;
      return Boolean(options.partialReplace || ((ref1 = options.onlyKeys) != null ? ref1.length : void 0) || ((ref2 = options.exceptKeys) != null ? ref2.length : void 0));
    };

    Turbolinks.fullPageNavigate = function(url) {
      if (url != null) {
        url = (new ComponentUrl(url)).absolute;
        triggerEvent('page:before-full-refresh', {
          url: url
        });
        activeDocument.location.href = url;
      }
    };

    Turbolinks.pushState = function(state, title, url) {
      return window.history.pushState(state, title, url);
    };

    Turbolinks.replaceState = function(state, title, url) {
      return window.history.replaceState(state, title, url);
    };

    Turbolinks.document = function(documentToUse) {
      if (documentToUse) {
        activeDocument = documentToUse;
      }
      return activeDocument;
    };

    fetchReplacement = function(url, options) {
      var k, ref1, v;
      triggerEvent('page:fetch', {
        url: url.absolute
      });
      if (xhr != null) {
        // Workaround for sinon xhr.abort()
        // https://github.com/sinonjs/sinon/issues/432#issuecomment-216917023
        xhr.readyState = 0;
        xhr.statusText = "abort";
        xhr.abort();
      }
      xhr = new XMLHttpRequest;
      xhr.open('GET', url.withoutHashForIE10compatibility(), true);
      xhr.setRequestHeader('Accept', 'text/html, application/xhtml+xml, application/xml');
      xhr.setRequestHeader('X-XHR-Referer', referer);
      if (options.headers == null) {
        options.headers = {};
      }
      ref1 = options.headers;
      for (k in ref1) {
        v = ref1[k];
        xhr.setRequestHeader(k, v);
      }
      xhr.onload = function() {
        if (xhr.status >= 500) {
          Turbolinks.fullPageNavigate(url);
        } else {
          Turbolinks.loadPage(url, xhr, options);
        }
        return xhr = null;
      };
      xhr.onerror = function() {
        // Workaround for sinon xhr.abort()
        if (xhr.statusText === "abort") {
          xhr = null;
          return;
        }
        return Turbolinks.fullPageNavigate(url);
      };
      xhr.send();
    };

    Turbolinks.loadPage = function(url, xhr, options) {
      var response, turbohead, upstreamDocument;
      if (options == null) {
        options = {};
      }
      triggerEvent('page:receive');
      response = new Response(xhr, url);
      if (options.updatePushState == null) {
        options.updatePushState = true;
      }
      options.partialReplace = isPartialReplace(response, options);
      if (!(upstreamDocument = response.document())) {
        triggerEvent('page:error', xhr);
        Turbolinks.fullPageNavigate(response.finalURL);
        return;
      }
      if (options.partialReplace) {
        updateBody(upstreamDocument, response, options);
        return;
      }
      turbohead = new TurboHead(activeDocument, upstreamDocument);
      if (turbohead.hasAssetConflicts()) {
        return Turbolinks.fullPageNavigate(response.finalURL);
      }
      return turbohead.waitForAssets().then(function(result) {
        if (!(result != null ? result.isCanceled : void 0)) {
          return updateBody(upstreamDocument, response, options);
        }
      });
    };

    updateBody = function(upstreamDocument, response, options) {
      var nodes, ref1;
      nodes = changePage((ref1 = upstreamDocument.querySelector('title')) != null ? ref1.textContent : void 0, removeNoscriptTags(upstreamDocument.querySelector('body')), CSRFToken.get(upstreamDocument).token, 'runScripts', options);
      if (options.updatePushState) {
        reflectNewUrl(response.finalURL);
      }
      if (!options.partialReplace) {
        Turbolinks.resetScrollPosition();
      }
      if (typeof options.callback === "function") {
        options.callback();
      }
      return triggerEvent('page:load', nodes);
    };

    changePage = function(title, body, csrfToken, runScripts, options) {
      var nodes, nodesToRefresh, ref1, ref2;
      if (options == null) {
        options = {};
      }
      if (title) {
        activeDocument.title = title;
      }
      if ((ref1 = options.onlyKeys) != null ? ref1.length : void 0) {
        nodesToRefresh = [].concat(getNodesWithRefreshAlways(), getNodesMatchingRefreshKeys(options.onlyKeys));
        nodes = refreshNodes(nodesToRefresh, body);
        if (anyAutofocusElement(nodes)) {
          setAutofocusElement();
        }
        return nodes;
      } else {
        refreshNodes(getNodesWithRefreshAlways(), body);
        persistStaticElements(body);
        if ((ref2 = options.exceptKeys) != null ? ref2.length : void 0) {
          refreshAllExceptWithKeys(options.exceptKeys, body);
        } else {
          deleteRefreshNeverNodes(body);
        }
        triggerEvent('page:before-replace');
        replaceNode(body, activeDocument.body);
        if (csrfToken != null) {
          CSRFToken.update(csrfToken);
        }
        setAutofocusElement();
        if (runScripts) {
          executeScriptTags();
        }
        currentState = window.history.state;
        triggerEvent('page:change');
        triggerEvent('page:update');
      }
    };

    getNodesMatchingRefreshKeys = function(keys) {
      var i, j, key, len, len1, matchingNodes, node, ref1;
      matchingNodes = [];
      for (i = 0, len = keys.length; i < len; i++) {
        key = keys[i];
        ref1 = TurboGraft.querySelectorAllTGAttribute(activeDocument, 'refresh', key);
        for (j = 0, len1 = ref1.length; j < len1; j++) {
          node = ref1[j];
          matchingNodes.push(node);
        }
      }
      return matchingNodes;
    };

    getNodesWithRefreshAlways = function() {
      var i, len, matchingNodes, node, ref1;
      matchingNodes = [];
      ref1 = TurboGraft.querySelectorAllTGAttribute(activeDocument, 'refresh-always');
      for (i = 0, len = ref1.length; i < len; i++) {
        node = ref1[i];
        matchingNodes.push(node);
      }
      return matchingNodes;
    };

    anyAutofocusElement = function(nodes) {
      var i, len, node;
      for (i = 0, len = nodes.length; i < len; i++) {
        node = nodes[i];
        if (node.querySelectorAll('input[autofocus], textarea[autofocus]').length > 0) {
          return true;
        }
      }
      return false;
    };

    setAutofocusElement = function() {
      var autofocusElement, list;
      autofocusElement = (list = activeDocument.querySelectorAll('input[autofocus], textarea[autofocus]'))[list.length - 1];
      if (autofocusElement && activeDocument.activeElement !== autofocusElement) {
        return autofocusElement.focus();
      }
    };

    deleteRefreshNeverNodes = function(body) {
      var i, len, node, ref1;
      ref1 = TurboGraft.querySelectorAllTGAttribute(body, 'refresh-never');
      for (i = 0, len = ref1.length; i < len; i++) {
        node = ref1[i];
        removeNode(node);
      }
    };

    refreshNodes = function(allNodesToBeRefreshed, body) {
      var existingNode, i, len, newNode, nodeId, parentIsRefreshing, refreshedNodes;
      triggerEvent('page:before-partial-replace', allNodesToBeRefreshed);
      parentIsRefreshing = function(node) {
        var i, len, potentialParent;
        for (i = 0, len = allNodesToBeRefreshed.length; i < len; i++) {
          potentialParent = allNodesToBeRefreshed[i];
          if (node !== potentialParent) {
            if (potentialParent.contains(node)) {
              return true;
            }
          }
        }
        return false;
      };
      refreshedNodes = [];
      for (i = 0, len = allNodesToBeRefreshed.length; i < len; i++) {
        existingNode = allNodesToBeRefreshed[i];
        if (parentIsRefreshing(existingNode)) {
          continue;
        }
        if (!(nodeId = existingNode.getAttribute('id'))) {
          throw new Error("Turbolinks refresh: Refresh key elements must have an id.");
        }
        if (newNode = body.querySelector("#" + nodeId)) {
          newNode = newNode.cloneNode(true);
          replaceNode(newNode, existingNode);
          if (newNode.nodeName === 'SCRIPT' && newNode.dataset.turbolinksEval !== "false") {
            executeScriptTag(newNode);
          } else {
            refreshedNodes.push(newNode);
          }
        } else if (!TurboGraft.hasTGAttribute(existingNode, "refresh-always")) {
          removeNode(existingNode);
        }
      }
      return refreshedNodes;
    };

    keepNodes = function(body, allNodesToKeep) {
      var existingNode, i, len, nodeId, remoteNode, results;
      results = [];
      for (i = 0, len = allNodesToKeep.length; i < len; i++) {
        existingNode = allNodesToKeep[i];
        if (!(nodeId = existingNode.getAttribute('id'))) {
          throw new Error("TurboGraft refresh: Kept nodes must have an id.");
        }
        if (remoteNode = body.querySelector("#" + nodeId)) {
          results.push(replaceNode(existingNode, remoteNode));
        } else {
          results.push(void 0);
        }
      }
      return results;
    };

    persistStaticElements = function(body) {
      var allNodesToKeep, i, len, node, nodes;
      allNodesToKeep = [];
      nodes = TurboGraft.querySelectorAllTGAttribute(activeDocument, 'tg-static');
      for (i = 0, len = nodes.length; i < len; i++) {
        node = nodes[i];
        allNodesToKeep.push(node);
      }
      keepNodes(body, allNodesToKeep);
    };

    refreshAllExceptWithKeys = function(keys, body) {
      var allNodesToKeep, i, j, key, len, len1, node, ref1;
      allNodesToKeep = [];
      for (i = 0, len = keys.length; i < len; i++) {
        key = keys[i];
        ref1 = TurboGraft.querySelectorAllTGAttribute(activeDocument, 'refresh', key);
        for (j = 0, len1 = ref1.length; j < len1; j++) {
          node = ref1[j];
          allNodesToKeep.push(node);
        }
      }
      keepNodes(body, allNodesToKeep);
    };

    executeScriptTags = function() {
      var i, len, ref1, script, scripts;
      scripts = Array.prototype.slice.call(activeDocument.body.querySelectorAll('script:not([data-turbolinks-eval="false"])'));
      for (i = 0, len = scripts.length; i < len; i++) {
        script = scripts[i];
        if ((ref1 = script.type) === '' || ref1 === 'text/javascript') {
          executeScriptTag(script);
        }
      }
    };

    executeScriptTag = function(script) {
      var attr, copy, i, len, nextSibling, parentNode, ref1;
      copy = activeDocument.createElement('script');
      ref1 = script.attributes;
      for (i = 0, len = ref1.length; i < len; i++) {
        attr = ref1[i];
        copy.setAttribute(attr.name, attr.value);
      }
      copy.appendChild(activeDocument.createTextNode(script.innerHTML));
      parentNode = script.parentNode, nextSibling = script.nextSibling;
      parentNode.removeChild(script);
      parentNode.insertBefore(copy, nextSibling);
    };

    removeNoscriptTags = function(node) {
      node.innerHTML = node.innerHTML.replace(/<noscript[\S\s]*?<\/noscript>/ig, '');
      return node;
    };

    reflectNewUrl = function(url) {
      if ((url = new ComponentUrl(url)).absolute !== referer) {
        Turbolinks.pushState({
          turbolinks: true,
          url: url.absolute
        }, '', url.absolute);
      }
    };

    rememberReferer = function() {
      return referer = activeDocument.location.href;
    };

    Turbolinks.rememberCurrentUrl = function() {
      return Turbolinks.replaceState({
        turbolinks: true,
        url: activeDocument.location.href
      }, '', activeDocument.location.href);
    };

    Turbolinks.rememberCurrentState = function() {
      return currentState = window.history.state;
    };

    recallScrollPosition = function(page) {
      return window.scrollTo(page.positionX, page.positionY);
    };

    Turbolinks.resetScrollPosition = function() {
      if (activeDocument.location.hash) {
        return activeDocument.location.href = activeDocument.location.href;
      } else {
        return window.scrollTo(0, 0);
      }
    };

    pageChangePrevented = function(url) {
      return !triggerEvent('page:before-change', url);
    };

    installHistoryChangeHandler = function(event) {
      var ref1;
      if ((ref1 = event.state) != null ? ref1.turbolinks : void 0) {
        return Turbolinks.visit(event.target.location.href);
      }
    };

    // Delay execution of function long enough to miss the popstate event
    // some browsers fire on the initial page load.
    bypassOnLoadPopstate = function(fn) {
      return setTimeout(fn, 500);
    };

    if (browserSupportsTurbolinks) {
      Turbolinks.visit = fetch;
      Turbolinks.rememberCurrentUrl();
      Turbolinks.rememberCurrentState();
      activeDocument.addEventListener('click', Click.installHandlerLast, true);
      bypassOnLoadPopstate(function() {
        return window.addEventListener('popstate', installHistoryChangeHandler, false);
      });
    } else {
      Turbolinks.visit = function(url) {
        return activeDocument.location.href = url;
      };
    }

    return Turbolinks;

  })();

}).call(this);
