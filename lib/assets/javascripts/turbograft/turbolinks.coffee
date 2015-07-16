xhr = null

installDocumentReadyPageEventTriggers = ->
  document.addEventListener 'DOMContentLoaded', ( ->
    triggerEvent 'page:change'
    triggerEvent 'page:update'
  ), true

installJqueryAjaxSuccessPageUpdateTrigger = ->
  if typeof jQuery isnt 'undefined'
    jQuery(document).on 'ajaxSuccess', (event, xhr, settings) ->
      return unless jQuery.trim xhr.responseText
      triggerEvent 'page:update'

# Handle bug in Firefox 26/27 where history.state is initially undefined
historyStateIsDefined =
  window.history.state != undefined or navigator.userAgent.match /Firefox\/2[6|7]/

browserSupportsPushState =
  window.history and window.history.pushState and window.history.replaceState and historyStateIsDefined

window.triggerEvent = (name, data) ->
  event = document.createEvent 'Events'
  event.data = data if data
  event.initEvent name, true, true
  document.dispatchEvent event

window.triggerEventFor = (name, node, data) ->
  event = document.createEvent 'Events'
  event.data = data if data
  event.initEvent name, true, true
  node.dispatchEvent event

popCookie = (name) ->
  value = document.cookie.match(new RegExp(name+"=(\\w+)"))?[1].toUpperCase() or ''
  document.cookie = name + '=; expires=Thu, 01-Jan-70 00:00:01 GMT; path=/'
  value

requestMethodIsSafe =
  popCookie('request_method') in ['GET','']

browserSupportsTurbolinks = browserSupportsPushState and requestMethodIsSafe

browserSupportsCustomEvents =
  document.addEventListener and document.createEvent

if browserSupportsCustomEvents
  installDocumentReadyPageEventTriggers()
  installJqueryAjaxSuccessPageUpdateTrigger()

replaceNode = (newNode, oldNode) ->
  replacedNode = oldNode.parentNode.replaceChild(newNode, oldNode)
  triggerEvent('page:after-node-removed', replacedNode)

removeNode = (node) ->
  removedNode = node.parentNode.removeChild(node)
  triggerEvent('page:after-node-removed', removedNode)

# TODO: triggerEvent should be accessible to all these guys
# on some kind of eventbus
# TODO: clean up everything above me ^
# TODO: decide on the public API
class window.Turbolinks
  createDocument = null
  currentState = null
  loadedAssets = null
  referer = null

  fetch = (url, options = {}) ->
    return if pageChangePrevented(url)
    url = new ComponentUrl url

    rememberReferer()

    options.partialReplace ?= false
    options.onlyKeys ?= []
    options.onLoadFunction = ->
      resetScrollPosition() unless options.onlyKeys.length
      options.callback?()

    fetchReplacement url, options

  @pushState: (state, title, url) ->
    window.history.pushState(state, title, url)

  @replaceState: (state, title, url) ->
    window.history.replaceState(state, title, url)

  fetchReplacement = (url, options) ->
    triggerEvent 'page:fetch', url: url.absolute

    xhr?.abort()
    xhr = new XMLHttpRequest
    xhr.open 'GET', url.withoutHashForIE10compatibility(), true
    xhr.setRequestHeader 'Accept', 'text/html, application/xhtml+xml, application/xml'
    xhr.setRequestHeader 'X-XHR-Referer', referer

    options.headers ?= {}

    for k,v of options.headers
      xhr.setRequestHeader k, v

    xhr.onload = ->
      if xhr.status >= 500
        document.location.href = url.absolute
      else
        Turbolinks.loadPage(url, xhr, options)

    xhr.onloadend = -> xhr = null
    xhr.onerror   = ->
      document.location.href = url.absolute

    xhr.send()

    return

  @loadPage: (url, xhr, options = {}) ->
    rememberReferer()

    triggerEvent 'page:receive'
    options.updatePushState ?= true

    if doc = processResponse(xhr, options.partialReplace)
      reflectNewUrl url if options.updatePushState
      nodes = changePage(extractTitleAndBody(doc)..., options)
      reflectRedirectedUrl(xhr) if options.updatePushState
      triggerEvent 'page:load', nodes
      options.onLoadFunction?()
    else
      document.location.href = url.absolute

    return

  changePage = (title, body, csrfToken, runScripts, options = {}) ->
    document.title = title if title
    options.onlyKeys ?= []
    options.exceptKeys ?= []

    if options.onlyKeys.length
      nodesToRefresh = [].concat(getNodesWithRefreshAlways(), getNodesMatchingRefreshKeys(options.onlyKeys))
      nodes = refreshNodes(nodesToRefresh, body)
      setAutofocusElement() if anyAutofocusElement(nodes)
      return nodes
    else
      refreshNodes(getNodesWithRefreshAlways(), body)
      persistStaticElements(body)
      if options.exceptKeys.length
        refreshAllExceptWithKeys(options.exceptKeys, body)
      else
        deleteRefreshNeverNodes(body)

      triggerEvent 'page:before-replace'
      replaceNode(body, document.body)
      CSRFToken.update csrfToken if csrfToken?
      setAutofocusElement()
      executeScriptTags() if runScripts
      currentState = window.history.state
      triggerEvent 'page:change'
      triggerEvent 'page:update'

    return

  getNodesMatchingRefreshKeys = (keys) ->
    matchingNodes = []
    for key in keys
      for node in TurboGraft.querySelectorAllTGAttribute(document, 'refresh', key)
        matchingNodes.push(node)

    return matchingNodes

  getNodesWithRefreshAlways = ->
    matchingNodes = []
    for node in TurboGraft.querySelectorAllTGAttribute(document, 'refresh-always')
      matchingNodes.push(node)

    return matchingNodes

  anyAutofocusElement = (nodes) ->
    for node in nodes
      if node.querySelectorAll('input[autofocus], textarea[autofocus]').length > 0
        return true

    false

  setAutofocusElement = ->
    autofocusElement = (list = document.querySelectorAll 'input[autofocus], textarea[autofocus]')[list.length - 1]
    if autofocusElement and document.activeElement isnt autofocusElement
      autofocusElement.focus()

  deleteRefreshNeverNodes = (body) ->
    for node in TurboGraft.querySelectorAllTGAttribute(body, 'refresh-never')
      removeNode(node)

    return

  refreshNodes = (allNodesToBeRefreshed, body) ->
    triggerEvent 'page:before-partial-replace', allNodesToBeRefreshed

    parentIsRefreshing = (node) ->
      for potentialParent in allNodesToBeRefreshed when node != potentialParent
        return true if potentialParent.contains(node)
      false

    refreshedNodes = []
    for existingNode in allNodesToBeRefreshed
      continue if parentIsRefreshing(existingNode)

      unless nodeId = existingNode.getAttribute('id')
        throw new Error "Turbolinks refresh: Refresh key elements must have an id."

      if newNode = body.querySelector("##{ nodeId }")
        newNode = newNode.cloneNode(true)
        replaceNode(newNode, existingNode)

        if newNode.nodeName == 'SCRIPT' && newNode.getAttribute("data-turbolinks-eval") != "false"
          executeScriptTag(newNode)
        else
          refreshedNodes.push(newNode)

      else if TurboGraft.getTGAttribute(existingNode, "refresh-always") == null
        removeNode(existingNode)

    refreshedNodes

  keepNodes = (body, allNodesToKeep) ->
    for existingNode in allNodesToKeep
      unless nodeId = existingNode.getAttribute('id')
        throw new Error("TurboGraft refresh: Kept nodes must have an id.")

      if remoteNode = body.querySelector("##{ nodeId }")
        replaceNode(existingNode, remoteNode)

  persistStaticElements = (body) ->
    allNodesToKeep = []

    nodes = TurboGraft.querySelectorAllTGAttribute(document, 'tg-static')
    allNodesToKeep.push(node) for node in nodes

    keepNodes(body, allNodesToKeep)
    return

  refreshAllExceptWithKeys = (keys, body) ->
    allNodesToKeep = []

    for key in keys
      for node in TurboGraft.querySelectorAllTGAttribute(document, 'refresh', key)
        allNodesToKeep.push(node)

    keepNodes(body, allNodesToKeep)
    return

  executeScriptTags = ->
    scripts = Array::slice.call document.body.querySelectorAll 'script:not([data-turbolinks-eval="false"])'
    for script in scripts when script.type in ['', 'text/javascript']
      executeScriptTag(script)
    return

  executeScriptTag = (script) ->
    copy = document.createElement 'script'
    copy.setAttribute attr.name, attr.value for attr in script.attributes
    copy.appendChild document.createTextNode script.innerHTML
    { parentNode, nextSibling } = script
    parentNode.removeChild script
    parentNode.insertBefore copy, nextSibling
    return

  removeNoscriptTags = (node) ->
    node.innerHTML = node.innerHTML.replace /<noscript[\S\s]*?<\/noscript>/ig, ''
    node

  reflectNewUrl = (url) ->
    if (url = new ComponentUrl url).absolute isnt referer
      Turbolinks.pushState { turbolinks: true, url: url.absolute }, '', url.absolute
    return

  reflectRedirectedUrl = (xhr) ->
    if location = xhr.getResponseHeader 'X-XHR-Redirected-To'
      location = new ComponentUrl location
      preservedHash = if location.hasNoHash() then document.location.hash else ''
      Turbolinks.replaceState currentState, '', location.href + preservedHash
    return

  rememberReferer = ->
    referer = document.location.href

  @rememberCurrentUrl: ->
    Turbolinks.replaceState { turbolinks: true, url: document.location.href }, '', document.location.href

  @rememberCurrentState: ->
    currentState = window.history.state

  recallScrollPosition = (page) ->
    window.scrollTo page.positionX, page.positionY

  resetScrollPosition = ->
    if document.location.hash
      document.location.href = document.location.href
    else
      window.scrollTo 0, 0

  pageChangePrevented = (url) ->
    !triggerEvent('page:before-change', url)

  processResponse = (xhr, partial = false) ->
    clientOrServerError = ->
      return false if xhr.status == 422 # we want to render form validations
      400 <= xhr.status < 600

    validContent = ->
      xhr.getResponseHeader('Content-Type').match /^(?:text\/html|application\/xhtml\+xml|application\/xml)(?:;|$)/

    extractTrackAssets = (doc) ->
      for node in doc.querySelector('head').childNodes when node.getAttribute?('data-turbolinks-track')?
        node.getAttribute('src') or node.getAttribute('href')

    assetsChanged = (doc) ->
      loadedAssets ||= extractTrackAssets document
      fetchedAssets  = extractTrackAssets doc
      fetchedAssets.length isnt loadedAssets.length or intersection(fetchedAssets, loadedAssets).length isnt loadedAssets.length

    intersection = (a, b) ->
      [a, b] = [b, a] if a.length > b.length
      value for value in a when value in b

    if !clientOrServerError() && validContent()
      doc = createDocument xhr.responseText
      changed = assetsChanged(doc)

      if doc && (!changed || partial)
        return doc

  extractTitleAndBody = (doc) ->
    title = doc.querySelector 'title'
    [ title?.textContent, removeNoscriptTags(doc.querySelector('body')), CSRFToken.get(doc).token, 'runScripts' ]

  installHistoryChangeHandler = (event) ->
    if event.state?.turbolinks
      Turbolinks.visit event.target.location.href

  # Delay execution of function long enough to miss the popstate event
  # some browsers fire on the initial page load.
  bypassOnLoadPopstate = (fn) ->
    setTimeout fn, 500

  createDocument = (html) ->
    if /<(html|body)/i.test(html)
      doc = document.documentElement.cloneNode()
      doc.innerHTML = html
    else
      doc = document.documentElement.cloneNode(true)
      doc.querySelector('body').innerHTML = html
    doc.head = doc.querySelector('head')
    doc.body = doc.querySelector('body')
    doc

  if browserSupportsTurbolinks
    @visit = fetch
    @rememberCurrentUrl()
    @rememberCurrentState()

    document.addEventListener 'click', Click.installHandlerLast, true

    bypassOnLoadPopstate ->
      window.addEventListener 'popstate', installHistoryChangeHandler, false

  else
    @visit = (url) -> document.location.href = url
