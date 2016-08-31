class window.TurboHead
  constructor: (@activeDocument, @upstreamDocument) ->

  update: (successCallback, failureCallback) ->
    activeAssets = extractTrackedAssets(@activeDocument)
    upstreamAssets = extractTrackedAssets(@upstreamDocument)

    newScripts = upstreamAssets
      .filter(filterForNodeType('SCRIPT'))
      .filter(noMatchFor({attribute: 'src', inCollection: activeAssets}))

    newLinks = upstreamAssets
      .filter(filterForNodeType('LINK'))
      .filter(noMatchFor({attribute: 'href', inCollection: activeAssets}))

    if newScripts.concat(newLinks).some(hasAssetConflicts(activeAssets))
      return failureCallback()

    updateTasks = [
      (done) => updateLinkTags(@activeDocument, newLinks, done),
      (done) => updateScriptTags(@activeDocument, newScripts, done)
    ]

    asyncSeries(updateTasks, successCallback)

extractTrackedAssets = (doc) ->
  [].slice.call(doc.querySelectorAll('[data-turbolinks-track]'))

filterForNodeType = (nodeType) ->
  (node) -> node.nodeName == nodeType

noMatchFor = ({attribute, inCollection}) ->
  (node) ->
    !inCollection.some((nodeFromCollection) -> node[attribute] == nodeFromCollection[attribute])

hasAssetConflicts = (activeAssets) ->
  (newNode) ->
    activeAssets.some((activeNode) ->
      trackName = newNode.dataset.turbolinksTrack
      trackName == activeNode.dataset.turbolinksTrack &&
      trackName != 'true'
    )

updateLinkTags = (activeDocument, newLinks, callback) ->
  # style tag load events don't work in all browsers
  # as such we just hope they load ¯\_(ツ)_/¯
  newLinks.forEach((linkNode) -> insertLinkTask(activeDocument, linkNode)(noOp))
  callback()

updateScriptTags = (activeDocument, newScripts, callback) ->
  asyncSeries(
    newScripts.map((scriptNode) -> insertScriptTask(activeDocument, scriptNode)),
    callback
  )

noOp = -> null

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
      done()
    newNode.addEventListener('load', onAssetEvent)
    newNode.addEventListener('error', onAssetEvent)
    activeDocument.head.appendChild(newNode)
    triggerEvent("page:after-#{name}-inserted", newNode)
