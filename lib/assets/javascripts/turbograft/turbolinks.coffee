Response = TurboGraft.Response
TurboHead = TurboGraft.TurboHead
jQuery = window.jQuery

xhr = null
activeDocument = document

installDocumentReadyPageEventTriggers = ->
  activeDocument.addEventListener 'DOMContentLoaded', ( ->
    triggerEvent 'page:change'
    triggerEvent 'page:update'
  ), true

installJqueryAjaxSuccessPageUpdateTrigger = ->
  if typeof jQuery isnt 'undefined'
    jQuery(activeDocument).on 'ajaxSuccess', (event, xhr, settings) ->
      return unless jQuery.trim xhr.responseText
      triggerEvent 'page:update'

# Handle bug in Firefox 26/27 where history.state is initially undefined
historyStateIsDefined =
  window.history.state != undefined or navigator.userAgent.match /Firefox\/2[6|7]/

browserSupportsPushState =
  window.history and window.history.pushState and window.history.replaceState and historyStateIsDefined

window.triggerEvent = (name, data) ->
  event = activeDocument.createEvent 'Events'
  event.data = data if data
  event.initEvent name, true, true
  activeDocument.dispatchEvent event

window.triggerEventFor = (name, node, data) ->
  event = activeDocument.createEvent 'Events'
  event.data = data if data
  event.initEvent name, true, true
  node.dispatchEvent event

popCookie = (name) ->
  value = activeDocument.cookie.match(new RegExp(name+"=(\\w+)"))?[1].toUpperCase() or ''
  activeDocument.cookie = name + '=; expires=Thu, 01-Jan-70 00:00:01 GMT; path=/'
  value

requestMethodIsSafe =
  popCookie('request_method') in ['GET','']

browserSupportsTurbolinks = browserSupportsPushState and requestMethodIsSafe

browserSupportsCustomEvents =
  activeDocument.addEventListener and activeDocument.createEvent

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
  currentState = null
  referer = null

  fetch = (url, options = {}) ->
    return if pageChangePrevented(url)
    url = new ComponentUrl url

    rememberReferer()

    fetchReplacement(url, options)

  isPartialReplace = (response, options) ->
    Boolean(
      options.partialReplace ||
      options.onlyKeys?.length ||
      options.exceptKeys?.length
    ) && !response.redirectedToNewUrl()

  @fullPageNavigate: (url) ->
    if url?
      url = (new ComponentUrl(url)).absolute
      triggerEvent('page:before-full-refresh', url: url)
      activeDocument.location.href = url
    return

  @pushState: (state, title, url) ->
    window.history.pushState(state, title, url)

  @replaceState: (state, title, url) ->
    window.history.replaceState(state, title, url)

  @document: (documentToUse) ->
    activeDocument = documentToUse if documentToUse
    activeDocument

  fetchReplacement = (url, options) ->
    triggerEvent 'page:fetch', url: url.absolute

    if xhr?
      # Workaround for sinon xhr.abort()
      # https://github.com/sinonjs/sinon/issues/432#issuecomment-216917023
      xhr.readyState = 0
      xhr.statusText = "abort"
      xhr.abort()

    xhr = new XMLHttpRequest

    xhr.open 'GET', url.withoutHashForIE10compatibility(), true
    xhr.setRequestHeader 'Accept', 'text/html, application/xhtml+xml, application/xml'
    xhr.setRequestHeader 'X-XHR-Referer', referer
    options.headers ?= {}

    for k,v of options.headers
      xhr.setRequestHeader k, v

    xhr.onload = ->
      if xhr.status >= 500
        Turbolinks.fullPageNavigate(url)
      else
        Turbolinks.loadPage(url, xhr, options)
      xhr = null

    xhr.onerror = ->
      # Workaround for sinon xhr.abort()
      if xhr.statusText == "abort"
        xhr = null
        return
      Turbolinks.fullPageNavigate(url)

    xhr.send()

    return

  @loadPage: (url, xhr, options = {}) ->
    triggerEvent 'page:receive'
    response = new Response(xhr, url)
    options.updatePushState ?= true
    options.partialReplace = isPartialReplace(response, options)

    unless upstreamDocument = response.document()
      triggerEvent 'page:error', xhr
      Turbolinks.fullPageNavigate(response.url)
      return

    if options.partialReplace
      updateBody(upstreamDocument, response, options)
      return

    turbohead = new TurboHead(activeDocument, upstreamDocument)
    if turbohead.hasAssetConflicts()
      return Turbolinks.fullPageNavigate(response.url)

    turbohead.waitForAssets().then((result) ->
      updateBody(upstreamDocument, response, options) unless result?.isCanceled
    )

  updateBody = (upstreamDocument, response, options) ->
    nodes = changePage(
      upstreamDocument.querySelector('title')?.textContent,
      removeNoscriptTags(upstreamDocument.querySelector('body')),
      CSRFToken.get(upstreamDocument).token,
      'runScripts',
      options
    )
    reflectNewUrl(response.url) if options.updatePushState

    Turbolinks.resetScrollPosition() unless options.partialReplace

    options.callback?()
    triggerEvent 'page:load', nodes

  changePage = (title, body, csrfToken, runScripts, options = {}) ->
    activeDocument.title = title if title

    if options.onlyKeys?.length
      nodesToRefresh = [].concat(getNodesWithRefreshAlways(), getNodesMatchingRefreshKeys(options.onlyKeys))
      nodes = refreshNodes(nodesToRefresh, body)
      setAutofocusElement() if anyAutofocusElement(nodes)
      return nodes
    else
      refreshNodes(getNodesWithRefreshAlways(), body)
      persistStaticElements(body)
      if options.exceptKeys?.length
        refreshAllExceptWithKeys(options.exceptKeys, body)
      else
        deleteRefreshNeverNodes(body)

      triggerEvent 'page:before-replace'
      replaceNode(body, activeDocument.body)
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
      for node in TurboGraft.querySelectorAllTGAttribute(activeDocument, 'refresh', key)
        matchingNodes.push(node)

    return matchingNodes

  getNodesWithRefreshAlways = ->
    matchingNodes = []
    for node in TurboGraft.querySelectorAllTGAttribute(activeDocument, 'refresh-always')
      matchingNodes.push(node)

    return matchingNodes

  anyAutofocusElement = (nodes) ->
    for node in nodes
      if node.querySelectorAll('input[autofocus], textarea[autofocus]').length > 0
        return true

    false

  setAutofocusElement = ->
    autofocusElement = (list = activeDocument.querySelectorAll 'input[autofocus], textarea[autofocus]')[list.length - 1]
    if autofocusElement and activeDocument.activeElement isnt autofocusElement
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

        if newNode.nodeName == 'SCRIPT' && newNode.dataset.turbolinksEval != "false"
          executeScriptTag(newNode)
        else
          refreshedNodes.push(newNode)

      else if !TurboGraft.hasTGAttribute(existingNode, "refresh-always")
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

    nodes = TurboGraft.querySelectorAllTGAttribute(activeDocument, 'tg-static')
    allNodesToKeep.push(node) for node in nodes

    keepNodes(body, allNodesToKeep)
    return

  refreshAllExceptWithKeys = (keys, body) ->
    allNodesToKeep = []

    for key in keys
      for node in TurboGraft.querySelectorAllTGAttribute(activeDocument, 'refresh', key)
        allNodesToKeep.push(node)

    keepNodes(body, allNodesToKeep)
    return

  executeScriptTags = ->
    scripts = Array::slice.call activeDocument.body.querySelectorAll 'script:not([data-turbolinks-eval="false"])'
    for script in scripts when script.type in ['', 'text/javascript']
      executeScriptTag(script)
    return

  executeScriptTag = (script) ->
    copy = activeDocument.createElement 'script'
    copy.setAttribute attr.name, attr.value for attr in script.attributes
    copy.appendChild activeDocument.createTextNode script.innerHTML
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

  reflectRedirectedUrl = (response) ->
    if url = response.redirectedTo
      url = new ComponentUrl(url)
      preservedHash = if url.hasNoHash() then activeDocument.location.hash else ''
      Turbolinks.replaceState(currentState, '', url.href + preservedHash)
    return

  rememberReferer = ->
    referer = activeDocument.location.href

  @rememberCurrentUrl: ->
    Turbolinks.replaceState { turbolinks: true, url: activeDocument.location.href }, '', activeDocument.location.href

  @rememberCurrentState: ->
    currentState = window.history.state

  recallScrollPosition = (page) ->
    window.scrollTo page.positionX, page.positionY

  @resetScrollPosition: ->
    if activeDocument.location.hash
      activeDocument.location.href = activeDocument.location.href
    else
      window.scrollTo 0, 0

  pageChangePrevented = (url) ->
    !triggerEvent('page:before-change', url)

  installHistoryChangeHandler = (event) ->
    if event.state?.turbolinks
      Turbolinks.visit event.target.location.href

  # Delay execution of function long enough to miss the popstate event
  # some browsers fire on the initial page load.
  bypassOnLoadPopstate = (fn) ->
    setTimeout fn, 500

  if browserSupportsTurbolinks
    @visit = fetch
    @rememberCurrentUrl()
    @rememberCurrentState()

    activeDocument.addEventListener 'click', Click.installHandlerLast, true

    bypassOnLoadPopstate ->
      window.addEventListener 'popstate', installHistoryChangeHandler, false

  else
    @visit = (url) -> activeDocument.location.href = url
