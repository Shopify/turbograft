transitionCacheEnabled  = false

currentState            = null
loadedAssets            = null

referer                 = null

createDocument          = null
xhr                     = null

class PageCache
  storage = {}
  simultaneousAdditionOffset = 0
  constructor: (@cacheSize = 10) ->
    storage = {}
    return this

  get: (key) ->
    storage[key]

  set: (key, value) ->
    if typeof value != "object"
      throw "Developer error: You must store objects in this cache"

    value['cachedAt'] = new Date().getTime() + (simultaneousAdditionOffset+=1)

    storage[key] = value
    @constrain()

  setCacheSize: (newSize) ->
    if /^[\d]+$/.test(newSize)
      @cacheSize = parseInt(newSize, 10)
      @constrain()
    else
      throw "Developer error: Invalid parameter '#{newSize}' for PageCache; must be integer"

  constrain: ->
    pageCacheKeys = Object.keys storage

    cacheTimesRecentFirst = pageCacheKeys.map (url) =>
      storage[url].cachedAt
    .sort (a, b) -> b - a

    for key in pageCacheKeys when storage[key].cachedAt <= cacheTimesRecentFirst[@cacheSize]
      triggerEvent 'page:expire', storage[key]
      delete storage[key]

  length: ->
    Object.keys(storage).length

pageCache = new PageCache()

window.PageCache = PageCache

fetch = (url, partialReplace = false, replaceContents = [], callback) ->
  url = new ComponentUrl url

  rememberReferer()
  cacheCurrentPage() if transitionCacheEnabled
  reflectNewUrl url

  if transitionCacheEnabled and cachedPage = transitionCacheFor(url.absolute)
    fetchHistory cachedPage
    fetchReplacement url, partialReplace, null, replaceContents
  else
    fetchReplacement url, partialReplace, ->
      resetScrollPosition() unless replaceContents.length
      callback?()
    , replaceContents

transitionCacheFor = (url) ->
  cachedPage = pageCache.get(url)
  cachedPage if cachedPage and !cachedPage.transitionCacheDisabled

enableTransitionCache = (enable = true) ->
  transitionCacheEnabled = enable

pushState = (state, title, url) ->
  window.history.pushState(state, title, url)
replaceState = (state, title, url) ->
  window.history.replaceState(state, title, url)

window.Turbolinks = ->
Turbolinks.replaceState = replaceState
Turbolinks.pushState = pushState

fetchReplacement = (url, partialReplace, onLoadFunction, replaceContents) ->
  triggerEvent 'page:fetch', url: url.absolute

  xhr?.abort()
  xhr = new XMLHttpRequest
  xhr.open 'GET', url.withoutHashForIE10compatibility(), true
  xhr.setRequestHeader 'Accept', 'text/html, application/xhtml+xml, application/xml'
  xhr.setRequestHeader 'X-XHR-Referer', referer

  xhr.onload = ->
    loadPage(url, xhr, partialReplace, onLoadFunction, replaceContents)

  xhr.onloadend = -> xhr = null
  xhr.onerror   = ->
    document.location.href = url.absolute

  xhr.send()

loadPage = (url, xhr, partialReplace = false, onLoadFunction = (->), replaceContents = []) ->
  triggerEvent 'page:receive'

  if doc = processResponse(xhr, partialReplace)
    nodes = changePage(extractTitleAndBody(doc)..., partialReplace, replaceContents)
    reflectRedirectedUrl(xhr)
    triggerEvent 'page:load', nodes
    onLoadFunction?()
  else
    document.location.href = url.absolute

fetchHistory = (cachedPage) ->
  xhr?.abort()
  changePage cachedPage.title, cachedPage.body, false
  recallScrollPosition cachedPage
  triggerEvent 'page:restore'


cacheCurrentPage = ->
  currentStateUrl = new ComponentUrl currentState.url

  pageCache.set currentStateUrl.absolute,
    url:                      currentStateUrl.relative,
    body:                     document.body,
    title:                    document.title,
    positionY:                window.pageYOffset,
    positionX:                window.pageXOffset,
    transitionCacheDisabled:  document.querySelector('[data-no-transition-cache]')?


changePage = (title, body, csrfToken, runScripts, partialReplace, replaceContents = []) ->
  document.title = title if title
  if replaceContents.length
    return refreshNodesWithKeys(replaceContents, body)

  if partialReplace
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

      if newNode.nodeName == 'SCRIPT'
        executeScriptTag(newNode)
      else
        refreshedNodes.push(newNode)

    else if existingNode.getAttribute("refresh-always") == null
      existingNode.parentNode.removeChild(existingNode)

  refreshedNodes

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

removeNoscriptTags = (node) ->
  node.innerHTML = node.innerHTML.replace /<noscript[\S\s]*?<\/noscript>/ig, ''
  node

reflectNewUrl = (url) ->
  if (url = new ComponentUrl url).absolute isnt referer
    Turbolinks.pushState { turbolinks: true, url: url.absolute }, '', url.absolute

reflectRedirectedUrl = (xhr) ->
  if location = xhr.getResponseHeader 'X-XHR-Redirected-To'
    location = new ComponentUrl location
    preservedHash = if location.hasNoHash() then document.location.hash else ''
    Turbolinks.replaceState currentState, '', location.href + preservedHash

rememberReferer = ->
  referer = document.location.href

rememberCurrentUrl = ->
  Turbolinks.replaceState { turbolinks: true, url: document.location.href }, '', document.location.href

rememberCurrentState = ->
  currentState = window.history.state

recallScrollPosition = (page) ->
  window.scrollTo page.positionX, page.positionY

resetScrollPosition = ->
  if document.location.hash
    document.location.href = document.location.href
  else
    window.scrollTo 0, 0


popCookie = (name) ->
  value = document.cookie.match(new RegExp(name+"=(\\w+)"))?[1].toUpperCase() or ''
  document.cookie = name + '=; expires=Thu, 01-Jan-70 00:00:01 GMT; path=/'
  value

triggerEvent = (name, data) ->
  event = document.createEvent 'Events'
  event.data = data if data
  event.initEvent name, true, true
  document.dispatchEvent event

pageChangePrevented = ->
  !triggerEvent 'page:before-change'

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

CSRFToken =
  get: (doc = document) ->
    node:   tag = doc.querySelector 'meta[name="csrf-token"]'
    token:  tag?.getAttribute? 'content'

  update: (latest) ->
    current = @get()
    if current.token? and latest? and current.token isnt latest
      current.node.setAttribute 'content', latest

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


# The ComponentUrl class converts a basic URL string into an object
# that behaves similarly to document.location.
#
# If an instance is created from a relative URL, the current document
# is used to fill in the missing attributes (protocol, host, port).
class ComponentUrl
  constructor: (@original = document.location.href) ->
    return @original if @original.constructor is ComponentUrl
    @_parse()

  withoutHash: -> @href.replace @hash, ''

  # Intention revealing function alias
  withoutHashForIE10compatibility: -> @withoutHash()

  hasNoHash: -> @hash.length is 0

  _parse: ->
    (@link ?= document.createElement 'a').href = @original
    { @href, @protocol, @host, @hostname, @port, @pathname, @search, @hash } = @link
    @origin = [@protocol, '//', @hostname].join ''
    @origin += ":#{@port}" unless @port.length is 0
    @relative = [@pathname, @search, @hash].join ''
    @absolute = @href

# The Link class derives from the ComponentUrl class, but is built from an
# existing link element.  Provides verification functionality for Turbolinks
# to use in determining whether it should process the link when clicked.
class Link extends ComponentUrl
  @HTML_EXTENSIONS: ['html']

  @allowExtensions: (extensions...) ->
    Link.HTML_EXTENSIONS.push extension for extension in extensions
    Link.HTML_EXTENSIONS

  constructor: (@link) ->
    return @link if @link.constructor is Link
    @original = @link.href
    super

  shouldIgnore: ->
    @_crossOrigin() or
      @_anchored() or
      @_nonHtml() or
      @_optOut() or
      @_target()

  _crossOrigin: ->
    @origin isnt (new ComponentUrl).origin

  _anchored: ->
    ((@hash and @withoutHash()) is (current = new ComponentUrl).withoutHash()) or
      (@href is current.href + '#')

  _nonHtml: ->
    @pathname.match(/\.[a-z]+$/g) and not @pathname.match(new RegExp("\\.(?:#{Link.HTML_EXTENSIONS.join('|')})?$", 'g'))

  _optOut: ->
    link = @link
    until ignore or link is document
      ignore = link.getAttribute('data-no-turbolink')?
      link = link.parentNode
    ignore

  _target: ->
    @link.target.length isnt 0


# The Click class handles clicked links, verifying if Turbolinks should
# take control by inspecting both the event and the link. If it should,
# the page change process is initiated. If not, control is passed back
# to the browser for default functionality.
class Click
  @installHandlerLast: (event) ->
    unless event.defaultPrevented
      document.removeEventListener 'click', Click.handle, false
      document.addEventListener 'click', Click.handle, false

  @handle: (event) ->
    new Click event

  constructor: (@event) ->
    return if @event.defaultPrevented
    @_extractLink()
    if @_validForTurbolinks()
      visit @link.href unless pageChangePrevented()
      @event.preventDefault()

  _extractLink: ->
    link = @event.target
    link = link.parentNode until !link.parentNode or link.nodeName is 'A'
    @link = new Link(link) if link.nodeName is 'A' and link.href.length isnt 0

  _validForTurbolinks: ->
    @link? and not (@link.shouldIgnore() or @_nonStandardClick())

  _nonStandardClick: ->
    @event.which > 1 or
      @event.metaKey or
      @event.ctrlKey or
      @event.shiftKey or
      @event.altKey


# Delay execution of function long enough to miss the popstate event
# some browsers fire on the initial page load.
bypassOnLoadPopstate = (fn) ->
  setTimeout fn, 500

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

installHistoryChangeHandler = (event) ->
  if event.state?.turbolinks
    if cachedPage = pageCache.get((new ComponentUrl(event.state.url)).absolute)
      cacheCurrentPage()
      fetchHistory cachedPage
    else
      visit event.target.location.href

initializeTurbolinks = ->
  rememberCurrentUrl()
  rememberCurrentState()
  createDocument = browserCompatibleDocumentParser()

  document.addEventListener 'click', Click.installHandlerLast, true

  bypassOnLoadPopstate ->
    window.addEventListener 'popstate', installHistoryChangeHandler, false

# Handle bug in Firefox 26/27 where history.state is initially undefined
historyStateIsDefined =
  window.history.state != undefined or navigator.userAgent.match /Firefox\/2[6|7]/

browserSupportsPushState =
  window.history and window.history.pushState and window.history.replaceState and historyStateIsDefined

browserIsntBuggy =
  !navigator.userAgent.match /CriOS\//

requestMethodIsSafe =
  popCookie('request_method') in ['GET','']

browserSupportsTurbolinks = browserSupportsPushState and browserIsntBuggy and requestMethodIsSafe

browserSupportsCustomEvents =
  document.addEventListener and document.createEvent

if browserSupportsCustomEvents
  installDocumentReadyPageEventTriggers()
  installJqueryAjaxSuccessPageUpdateTrigger()

if browserSupportsTurbolinks
  visit = fetch
  initializeTurbolinks()
else
  visit = (url) -> document.location.href = url

# Public API
#   Turbolinks.visit(url)
#   Turbolinks.enableTransitionCache()
#   Turbolinks.allowLinkExtensions('md')
#   Turbolinks.supported
window.Turbolinks.visit = visit
window.Turbolinks.enableTransitionCache = enableTransitionCache
window.Turbolinks.allowLinkExtensions = Link.allowExtensions
window.Turbolinks.supported = browserSupportsTurbolinks
window.Turbolinks.loadPage = loadPage
