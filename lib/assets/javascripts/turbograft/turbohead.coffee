class window.TurboHead
  constructor: (@activeDocument, @upstreamDocument) ->

  update: (successCallback, failureCallback) ->
    activeAssets = extractTrackedAssets(@activeDocument)
    upstreamAssets = extractTrackedAssets(@upstreamDocument)
    {activeScripts, newScripts} = processScripts(activeAssets, upstreamAssets)

    if hasScriptConflict(activeScripts, newScripts)
      return failureCallback()

    updateLinkTags(activeAssets, upstreamAssets)
    updateScriptTags(@activeDocument, newScripts, successCallback)

updateLinkTags = (activeAssets, upstreamAssets) ->
  activeLinks = activeAssets.filter(filterForNodeType('LINK'))
  upstreamLinks = upstreamAssets.filter(filterForNodeType('LINK'))
  remainingActiveLinks = removeStaleLinks(activeLinks, upstreamLinks)
  reorderedActiveLinks = reorderActiveLinks(remainingActiveLinks, upstreamLinks)
  insertNewLinks(reorderedActiveLinks, upstreamLinks)

updateScriptTags = (activeDocument, newScripts, callback) ->
  asyncSeries(
    newScripts.map((scriptNode) -> insertScriptTask(activeDocument, scriptNode)),
    callback
  )

extractTrackedAssets = (doc) ->
  [].slice.call(doc.querySelectorAll('[data-turbolinks-track]'))

filterForNodeType = (nodeType) ->
  (node) -> node.nodeName == nodeType

hasScriptConflict = (activeScripts, newScripts) ->
  hasExistingScriptAssetName = (upstreamNode) ->
    activeScripts.some (activeNode) ->
      upstreamNode.dataset.turbolinksTrackScriptAs == activeNode.dataset.turbolinksTrackScriptAs

  newScripts.some(hasExistingScriptAssetName)

asyncSeries = (tasks, callback) ->
  return callback() if tasks.length == 0
  task = tasks.shift()
  task(-> asyncSeries(tasks, callback))

insertScriptTask = (activeDocument, scriptNode) ->
  # We need to clone script tags in order to ensure that the browser executes them.
  newNode = activeDocument.createElement('SCRIPT')
  newNode.setAttribute(attr.name, attr.value) for attr in scriptNode.attributes
  newNode.appendChild(activeDocument.createTextNode(scriptNode.innerHTML))

  return (done) ->
    onScriptEvent = (event) ->
      triggerEvent('page:script-error', event) if event.type == 'error'
      newNode.removeEventListener('load', onScriptEvent)
      newNode.removeEventListener('error', onScriptEvent)
      done()
    newNode.addEventListener('load', onScriptEvent)
    newNode.addEventListener('error', onScriptEvent)
    activeDocument.head.appendChild(newNode)
    triggerEvent('page:after-script-inserted', newNode)

processScripts = (activeAssets, upstreamAssets) ->
  activeScripts = activeAssets.filter(filterForNodeType('SCRIPT'))
  upstreamScripts = upstreamAssets.filter(filterForNodeType('SCRIPT'))
  hasNewSrc = (upstreamNode) ->
    activeScripts.every (activeNode) ->
      upstreamNode.src != activeNode.src

  newScripts = upstreamScripts.filter(hasNewSrc)

  {activeScripts, newScripts}

removeStaleLinks = (activeLinks, upstreamLinks) ->
  isStaleLink = (link) ->
    upstreamLinks.every (upstreamLink) ->
      upstreamLink.href != link.href

  staleLinks = activeLinks.filter(isStaleLink)

  for staleLink in staleLinks
    removedLink = document.head.removeChild(staleLink)
    triggerEvent('page:after-link-removed', removedLink)

  activeLinks.filter((link) -> !isStaleLink(link))

reorderAlreadyExists = (link1, link2, reorders) ->
  reorders.some (reorderPair) ->
    link1 in reorderPair && link2 in reorderPair

generateReorderGraph = (activeLinks, upstreamLinks) ->
  reorders = []
  for activeLink1 in activeLinks
    for activeLink2 in activeLinks
      continue if activeLink1.href == activeLink2.href
      continue if reorderAlreadyExists(activeLink1, activeLink2, reorders)

      upstreamLink1 = upstreamLinks.filter((link) -> link.href == activeLink1.href)[0]
      upstreamLink2 = upstreamLinks.filter((link) -> link.href == activeLink2.href)[0]

      orderHasChanged =
        (activeLinks.indexOf(activeLink1) < activeLinks.indexOf(activeLink2)) !=
        (upstreamLinks.indexOf(upstreamLink1) < upstreamLinks.indexOf(upstreamLink2))

      reorders.push([activeLink1, activeLink2]) if orderHasChanged
  reorders

nextMove = (activeLinks, reorders) ->
  changesAssociatedTo = (link) ->
    reorders.filter (reorderPair) ->
      link in reorderPair

  linksSortedByMovePriority = activeLinks
    .slice()
    .sort (link1, link2) ->
      changesAssociatedTo(link2).length - changesAssociatedTo(link1).length

  linkToMove = linksSortedByMovePriority[0]

  linksToPassBy = changesAssociatedTo(linkToMove).map (reorderPair) ->
    (reorderPair.filter (link) -> link.href != linkToMove.href)[0]

  {linkToMove, linksToPassBy}

reorderActiveLinks = (activeLinks, upstreamLinks) ->
  activeLinksCopy = activeLinks.slice()
  pendingReorders = generateReorderGraph(activeLinksCopy, upstreamLinks)

  removeReorder = (link1, link2) ->
    reorderToRemove = (pendingReorders.filter (reorderPair) ->
      link1 in reorderPair && link2 in reorderPair)[0]
    indexToRemove = pendingReorders.indexOf(reorderToRemove)
    pendingReorders.splice(indexToRemove, 1)

  addNewReorder = (link1, link2) ->
    pendingReorders.push [link1, link2]

  markReorderAsFinished = (linkToMove, linkToPass, remainingLinksToPass) ->
    removeReorder(linkToMove, linkToPass)
    removalIndex = remainingLinksToPass.indexOf(linkToPass)
    remainingLinksToPass.splice(removalIndex, 1)

  removeLink = (linkToRemove, indexOfLink) ->
    removedLink = document.head.removeChild(linkToRemove)
    triggerEvent('page:after-link-removed', removedLink)
    activeLinksCopy.splice(indexOfLink, 1)

  performMove = (linkToMove, linksToPassBy) ->
    moveDirection = if activeLinksCopy.indexOf(linkToMove) > activeLinksCopy.indexOf(linksToPassBy[0]) then 'UP' else 'DOWN'
    startIndex = activeLinksCopy.indexOf(linkToMove)

    switch moveDirection
      when 'UP'
        for i in [(startIndex - 1)..0]
          currentLink = activeLinksCopy[i]
          if currentLink in linksToPassBy
            markReorderAsFinished(linkToMove, currentLink, linksToPassBy)

            if linksToPassBy.length == 0
              removeLink(linkToMove, startIndex)

              document.head.insertBefore(linkToMove, activeLinksCopy[i])
              activeLinksCopy.splice(i, 0, linkToMove)
              triggerEvent('page:after-link-inserted', linkToMove)
              return
          else
            addNewReorder(linkToMove, currentLink, pendingReorders)
      when 'DOWN'
        for i in [(startIndex + 1)...activeLinksCopy.length]
          currentLink = activeLinksCopy[i]
          if currentLink in linksToPassBy
            markReorderAsFinished(linkToMove, currentLink, linksToPassBy)

            if linksToPassBy.length == 0
              removeLink(linkToMove, startIndex)

              targetIndex = i - 1
              if targetIndex == activeLinksCopy.length - 1
                document.head.appendChild(linkToMove)
                activeLinksCopy.push(linkToMove)
              else
                document.head.insertBefore(linkToMove, activeLinksCopy[targetIndex + 1])
                activeLinksCopy.splice(targetIndex + 1, 0, linkToMove)
              triggerEvent('page:after-link-inserted', linkToMove)
              return
          else
            addNewReorder(linkToMove, currentLink, pendingReorders)

  while pendingReorders.length > 0
    {linkToMove, linksToPassBy} = nextMove(activeLinksCopy, pendingReorders)
    performMove(linkToMove, linksToPassBy)

  activeLinksCopy

insertNewLinks = (activeLinks, upstreamLinks) ->
  isNewLink = (link) ->
    activeLinks.every (activeLink) ->
      activeLink.href != link.href

  upstreamLinks
    .filter(isNewLink)
    .reverse() # This is because we can't insert before a sibling that hasn't been inserted yet.
    .forEach (newUpstreamLink) ->
      index = upstreamLinks.indexOf(newUpstreamLink)
      newActiveLink = newUpstreamLink.cloneNode()
      if index == upstreamLinks.length - 1
        document.head.appendChild(newActiveLink)
        activeLinks.push(newActiveLink)
      else
        targetIndex = activeLinks.indexOf((activeLinks.filter (link) ->
          link.href == upstreamLinks[index + 1].href)[0])
        document.head.insertBefore(newActiveLink, activeLinks[targetIndex])
        activeLinks.splice(targetIndex, 0, newActiveLink)
      triggerEvent('page:after-link-inserted', newActiveLink)
