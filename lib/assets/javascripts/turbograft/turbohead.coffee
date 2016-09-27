TRACKED_ASSET_SELECTOR = '[data-turbolinks-track]'
TRACKED_ATTRIBUTE_NAME = 'turbolinksTrack'
ANONYMOUS_TRACK_VALUE = 'true'

scriptPromises = {}
resolvePreviousRequest = null

waitForCompleteDownloads = ->
  loadingPromises = Object.keys(scriptPromises).map (url) ->
    scriptPromises[url]
  Promise.all(loadingPromises)

class TurboGraft.TurboHead
  constructor: (@activeDocument, @upstreamDocument) ->
    @activeAssets = extractTrackedAssets(@activeDocument)
    @upstreamAssets = extractTrackedAssets(@upstreamDocument)
    @newScripts = @upstreamAssets
      .filter(attributeMatches('nodeName', 'SCRIPT'))
      .filter(noAttributeMatchesIn('src', @activeAssets))

    @newLinks = @upstreamAssets
      .filter(attributeMatches('nodeName', 'LINK'))
      .filter(noAttributeMatchesIn('href', @activeAssets))

  @_testAPI: {
    reset: ->
      scriptPromises = {}
      resolvePreviousRequest = null
  }

  hasChangedAnonymousAssets: () ->
    anonymousUpstreamAssets = @upstreamAssets
      .filter(datasetMatches(TRACKED_ATTRIBUTE_NAME, ANONYMOUS_TRACK_VALUE))
    anonymousActiveAssets = @activeAssets
      .filter(datasetMatches(TRACKED_ATTRIBUTE_NAME, ANONYMOUS_TRACK_VALUE))

    if anonymousActiveAssets.length != anonymousUpstreamAssets.length
      return true

    noMatchingSrc = noAttributeMatchesIn('src', anonymousUpstreamAssets)
    noMatchingHref = noAttributeMatchesIn('href', anonymousUpstreamAssets)

    anonymousActiveAssets.some((node) ->
      noMatchingSrc(node) || noMatchingHref(node)
    )

  hasNamedAssetConflicts: () ->
    @newScripts
      .concat(@newLinks)
      .filter(noDatasetMatches(TRACKED_ATTRIBUTE_NAME, ANONYMOUS_TRACK_VALUE))
      .some(datasetMatchesIn(TRACKED_ATTRIBUTE_NAME, @activeAssets))

  hasAssetConflicts: () ->
    @hasNamedAssetConflicts() || @hasChangedAnonymousAssets()

  waitForAssets: () ->
    resolvePreviousRequest?(isCanceled: true)

    new Promise((resolve) =>
      resolvePreviousRequest = resolve
      waitForCompleteDownloads()
        .then(@_insertNewAssets)
        .then(waitForCompleteDownloads)
        .then(resolve)
    )

  _insertNewAssets: () =>
    updateLinkTags(@activeDocument, @newLinks)
    updateScriptTags(@activeDocument, @newScripts)

extractTrackedAssets = (doc) ->
  [].slice.call(doc.querySelectorAll(TRACKED_ASSET_SELECTOR))

attributeMatches = (attribute, value) ->
  (node) -> node[attribute] == value

attributeMatchesIn = (attribute, collection) ->
  (node) ->
    collection.some((nodeFromCollection) -> node[attribute] == nodeFromCollection[attribute])

noAttributeMatchesIn = (attribute, collection) ->
  (node) ->
    !collection.some((nodeFromCollection) -> node[attribute] == nodeFromCollection[attribute])

datasetMatches = (attribute, value) ->
  (node) -> node.dataset[attribute] == value

noDatasetMatches = (attribute, value) ->
  (node) -> node.dataset[attribute] != value

datasetMatchesIn = (attribute, collection) ->
  (node) ->
    value = node.dataset[attribute]
    collection.some(datasetMatches(attribute, value))

noDatasetMatchesIn = (attribute, collection) ->
  (node) ->
    value = node.dataset[attribute]
    !collection.some(datasetMatches(attribute, value))

updateLinkTags = (activeDocument, newLinks) ->
  # style tag load events don't work in all browsers
  # as such we just hope they load ¯\_(ツ)_/¯
  newLinks.forEach((linkNode) ->
    newNode = linkNode.cloneNode()
    activeDocument.head.appendChild(newNode)
    triggerEvent("page:after-link-inserted", newNode)
  )

updateScriptTags = (activeDocument, newScripts) ->
  promise = Promise.resolve()
  newScripts.forEach (scriptNode) ->
    promise = promise.then(-> insertScript(activeDocument, scriptNode))
  promise

insertScript = (activeDocument, scriptNode) ->
  url = scriptNode.src
  if scriptPromises[url]
    return scriptPromises[url]

  # Clone script tags to guarantee browser execution.
  newNode = activeDocument.createElement('SCRIPT')
  newNode.setAttribute(attr.name, attr.value) for attr in scriptNode.attributes
  newNode.appendChild(activeDocument.createTextNode(scriptNode.innerHTML))

  scriptPromises[url] = new Promise((resolve) ->
    onAssetEvent = (event) ->
      if event.type == 'error'
        event.url = url
        triggerEvent("page:script-error", event) if event.type == 'error'

      newNode.removeEventListener('load', onAssetEvent)
      newNode.removeEventListener('error', onAssetEvent)
      resolve()

    newNode.addEventListener('load', onAssetEvent)
    newNode.addEventListener('error', onAssetEvent)
    activeDocument.head.appendChild(newNode)
    triggerEvent("page:after-script-inserted", newNode)
  )
