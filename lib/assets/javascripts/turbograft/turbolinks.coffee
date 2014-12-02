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

browserIsntBuggy =
  !navigator.userAgent.match /CriOS\//

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

browserSupportsTurbolinks = browserSupportsPushState and browserIsntBuggy and requestMethodIsSafe

browserSupportsCustomEvents =
  document.addEventListener and document.createEvent

if browserSupportsCustomEvents
  installDocumentReadyPageEventTriggers()
  installJqueryAjaxSuccessPageUpdateTrigger()

# TODO: triggerEvent should be accessible to all these guys
# on some kind of eventbus
# TODO: clean up everything above me ^
# TODO: decide on the public API
class window.Turbolinks
  createDocument = null
  currentState = null
  loadedAssets = null
  referer = null

  fetch = (url, partialReplace = false, replaceContents = [], callback) ->
    return if pageChangePrevented(url)
    url = new ComponentUrl url

    rememberReferer()

    fetchReplacement url, partialReplace, ->
      resetScrollPosition() unless replaceContents.length
      callback?()
    , replaceContents

  @pushState: (state, title, url) ->
    window.history.pushState(state, title, url)

  @replaceState: (state, title, url) ->
    window.history.replaceState(state, title, url)

  fetchReplacement = (url, partialReplace, onLoadFunction, replaceContents) ->
    triggerEvent 'page:fetch', url: url.absolute

    xhr?.abort()
    xhr = new XMLHttpRequest
    xhr.open 'GET', url.withoutHashForIE10compatibility(), true
    xhr.setRequestHeader 'Accept', 'text/html, application/xhtml+xml, application/xml'
    xhr.setRequestHeader 'X-XHR-Referer', referer

    xhr.onload = ->
      if xhr.status >= 500
        document.location.href = url.absolute
      else
        Turbolinks.loadPage(url, xhr, partialReplace, onLoadFunction, replaceContents)

    xhr.onloadend = -> xhr = null
    xhr.onerror   = ->
      document.location.href = url.absolute

    xhr.send()

    return

  @loadPage: (url, xhr, partialReplace = false, onLoadFunction = (->), replaceContents = [], replaceAllExcept = []) ->
    triggerEvent 'page:receive'

    if doc = processResponse(xhr, partialReplace)
      reflectNewUrl url
      nodes = changePage(extractTitleAndBody(doc)..., partialReplace, replaceContents, replaceAllExcept)
      reflectRedirectedUrl(xhr)
      triggerEvent 'page:load', nodes
      onLoadFunction?()
    else
      document.location.href = url.absolute

    return

  changePage = (title, body, csrfToken, runScripts, partialReplace, replaceContents = [], replaceAllExcept = []) ->
    document.title = title if title
    if replaceContents.length
      return refreshNodesWithKeys(replaceContents, body)
    else
      if replaceAllExcept.length
        refreshAllExceptWithKeys(replaceAllExcept, body)
      else
        deleteRefreshNeverNodes(body)

      triggerEvent 'page:before-replace'
      document.documentElement.replaceChild body, document.body
      CSRFToken.update csrfToken if csrfToken?
      executeScriptTags() if runScripts
      currentState = window.history.state
      triggerEvent 'page:change'
      triggerEvent 'page:update'

    return

  deleteRefreshNeverNodes = (body) ->
    for node in body.querySelectorAll('[refresh-never]')
      node.parentNode.removeChild(node)

    return

  refreshNodesWithKeys = (keys, body) ->
    allNodesToBeRefreshed = []
    for node in document.querySelectorAll("[refresh-always]")
      allNodesToBeRefreshed.push(node)

    for key in keys
      for node in document.querySelectorAll("[refresh=#{key}]")
        allNodesToBeRefreshed.push(node)

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
        existingNode.parentNode.replaceChild(newNode, existingNode)

        if newNode.nodeName == 'SCRIPT' && newNode.getAttribute("data-turbolinks-eval") != "false"
          executeScriptTag(newNode)
        else
          refreshedNodes.push(newNode)

      else if existingNode.getAttribute("refresh-always") == null
        existingNode.parentNode.removeChild(existingNode)

    refreshedNodes

  refreshAllExceptWithKeys = (keys, body) ->
    allNodesToKeep = []

    for key in keys
      for node in document.querySelectorAll("[refresh=#{key}]")
        allNodesToKeep.push(node)

    for existingNode in allNodesToKeep
      unless nodeId = existingNode.getAttribute('id')
        throw new Error "Turbolinks refresh: Refresh key elements must have an id."

      remoteNode = body.querySelector("##{ nodeId }")
      remoteNode.parentNode.replaceChild(existingNode, remoteNode)

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
      for node in doc.head.childNodes when node.getAttribute?('data-turbolinks-track')?
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
    [ title?.textContent, removeNoscriptTags(doc.body), CSRFToken.get(doc).token, 'runScripts' ]

  installHistoryChangeHandler = (event) ->
    if event.state?.turbolinks
      Turbolinks.visit event.target.location.href

  # Delay execution of function long enough to miss the popstate event
  # some browsers fire on the initial page load.
  bypassOnLoadPopstate = (fn) ->
    setTimeout fn, 500

  browserCompatibleDocumentParser = ->
    createDocumentUsingParser = (html) ->
      (new DOMParser).parseFromString html, 'text/html'

    createDocumentUsingDOM = (html) ->
      doc = document.implementation.createHTMLDocument ''
      doc.documentElement.innerHTML = html
      doc

    createDocumentUsingWrite = (html) ->
      doc = document.implementation.createHTMLDocument ''
      doc.open 'replace'
      doc.write html
      doc.close()
      doc

    # Use createDocumentUsingParser if DOMParser is defined and natively
    # supports 'text/html' parsing (Firefox 12+, IE 10)
    #
    # Use createDocumentUsingDOM if createDocumentUsingParser throws an exception
    # due to unsupported type 'text/html' (Firefox < 12, Opera)
    #
    # Use createDocumentUsingWrite if:
    #  - DOMParser isn't defined
    #  - createDocumentUsingParser returns null due to unsupported type 'text/html' (Chrome, Safari)
    #  - createDocumentUsingDOM doesn't create a valid HTML document (safeguarding against potential edge cases)
    try
      if window.DOMParser
        testDoc = createDocumentUsingParser '<html><body><p>test'
        createDocumentUsingParser
    catch e
      testDoc = createDocumentUsingDOM '<html><body><p>test'
      createDocumentUsingDOM
    finally
      unless testDoc?.body?.childNodes.length is 1
        return createDocumentUsingWrite

  if browserSupportsTurbolinks
    @visit = fetch
    @rememberCurrentUrl()
    @rememberCurrentState()
    createDocument = browserCompatibleDocumentParser()

    document.addEventListener 'click', Click.installHandlerLast, true

    bypassOnLoadPopstate ->
      window.addEventListener 'popstate', installHistoryChangeHandler, false

  else
    @visit = (url) -> document.location.href = url
