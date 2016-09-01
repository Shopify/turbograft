TRACKED_ASSET_SELECTOR = '[data-turbolinks-track]'
TRACKED_ATTRIBUTE_NAME = 'turbolinksTrack'
ANONYMOUS_TRACK_VALUE = 'true'

class window.TurboHead
  constructor: (@activeDocument, @upstreamDocument) ->
    @activeAssets = extractTrackedAssets(@activeDocument)
    @upstreamAssets = extractTrackedAssets(@upstreamDocument)
    @newScripts = @upstreamAssets
      .filter(attributeMatches('nodeName', 'SCRIPT'))
      .filter(noAttributeMatchesIn('src', @activeAssets))

    @newLinks = @upstreamAssets
      .filter(attributeMatches('nodeName', 'LINK'))
      .filter(noAttributeMatchesIn('href', @activeAssets))

  hasChangedAnonymousAssets: () ->
    anonymousUpstreamAssets = @upstreamAssets
      .filter(datasetMatches(TRACKED_ATTRIBUTE_NAME, ANONYMOUS_TRACK_VALUE))
    anonymousActiveAssets = @activeAssets
      .filter(datasetMatches(TRACKED_ATTRIBUTE_NAME, ANONYMOUS_TRACK_VALUE))

    if anonymousActiveAssets.length != anonymousUpstreamAssets.length
      return true

    anonymousActiveAssets.some(
      noAttributeMatchesIn(TRACKED_ATTRIBUTE_NAME, anonymousUpstreamAssets)
    )

  hasNamedAssetConflicts: () ->
    @newScripts
      .concat(@newLinks)
      .filter(noDatasetMatches(TRACKED_ATTRIBUTE_NAME, ANONYMOUS_TRACK_VALUE))
      .some(datasetMatchesIn(TRACKED_ATTRIBUTE_NAME, @activeAssets))

  hasAssetConflicts: () ->
    @hasNamedAssetConflicts() || @hasChangedAnonymousAssets()

  insertNewAssets: (callback) ->
    updateLinkTags(@activeDocument, @newLinks)
    updateScriptTags(@activeDocument, @newScripts, callback)

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
  newLinks.forEach((linkNode) -> insertLinkTask(activeDocument, linkNode)())

updateScriptTags = (activeDocument, newScripts, callback) ->
  asyncSeries(
    newScripts.map((scriptNode) -> insertScriptTask(activeDocument, scriptNode)),
    callback
  )

asyncSeries = (tasks, callback) ->
  return callback() if tasks.length == 0
  task = tasks.shift()
  task(-> asyncSeries(tasks, callback))

insertScriptTask = (activeDocument, scriptNode) ->
  # We need to clone script tags in order to ensure that the browser executes them.
  newNode = activeDocument.createElement('SCRIPT')
  newNode.setAttribute(attr.name, attr.value) for attr in scriptNode.attributes
  newNode.appendChild(activeDocument.createTextNode(scriptNode.innerHTML))
  insertAssetTask(activeDocument, newNode, 'script')

insertLinkTask = (activeDocument, node) ->
  insertAssetTask(activeDocument, node.cloneNode(), 'link')

insertAssetTask = (activeDocument, newNode, name) ->
  (done) ->
    onAssetEvent = (event) ->
      triggerEvent("page:#{name}-error", event) if event.type == 'error'
      newNode.removeEventListener('load', onAssetEvent)
      newNode.removeEventListener('error', onAssetEvent)
      done() if typeof done == 'function'
    newNode.addEventListener('load', onAssetEvent)
    newNode.addEventListener('error', onAssetEvent)
    activeDocument.head.appendChild(newNode)
    triggerEvent("page:after-#{name}-inserted", newNode)
