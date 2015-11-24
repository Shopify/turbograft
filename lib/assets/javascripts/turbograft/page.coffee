window.Page = {} if !window.Page

Page.visit = (url, opts={}) ->
  if opts.reload
    window.location = url
  else
    Turbolinks.visit(url)

Page.refresh = (options = {}, callback) ->
  newUrl = if options.url
    options.url
  else if options.queryParams
    paramString = $.param(options.queryParams)
    paramString = "?#{paramString}" if paramString
    location.pathname + paramString
  else
    location.href

  if options.response
    options.partialReplace = true
    options.onLoadFunction = callback

    url = options.url
    xhr = options.response
    delete options.response
    delete options.url
    Turbolinks.loadPage url, xhr, options
  else
    options.partialReplace = true
    options.callback = callback if callback

    Turbolinks.visit newUrl, options

Page.open = ->
  window.open(arguments...)

# Providing hooks for objects to set up destructors:
onReplaceCallbacks = []

# e.g., Page.onReplace(node, unbindListenersFnc)
# unbindListenersFnc will be called if the node in question is partially replaced
# or if a full replace occurs.  It will be called only once
Page.onReplace = (node, callback) ->
  throw new Error("Page.onReplace: Node and callback must both be specified") if !node || !callback
  throw new Error("Page.onReplace: Callback must be a function") if !isFunction(callback)
  onReplaceCallbacks.push({node, callback})

# option C from http://jsperf.com/alternative-isfunction-implementations
isFunction = (object) ->
  !!(object && object.constructor && object.call && object.apply)

# roughly based on http://davidwalsh.name/check-parent-node (note, OP is incorrect)
contains = (parentNode, childNode) ->
  if parentNode.contains
    parentNode.contains(childNode)
  else # old browser compatability
    !!((parentNode == childNode) || (parentNode.compareDocumentPosition(childNode) & Node.DOCUMENT_POSITION_CONTAINED_BY))

document.addEventListener 'page:before-partial-replace', (event) ->
  replacedNodes = event.data

  unprocessedOnReplaceCallbacks = []
  for entry in onReplaceCallbacks
    fired = false
    for replacedNode in replacedNodes
      if contains(replacedNode, entry.node)
        entry.callback()
        fired = true
        break

    unless fired
      unprocessedOnReplaceCallbacks.push(entry)

  onReplaceCallbacks = unprocessedOnReplaceCallbacks

document.addEventListener 'page:before-replace', (event) ->
  for entry in onReplaceCallbacks
    entry.callback()
  onReplaceCallbacks = []
