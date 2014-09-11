# The glue between Turbolinks, the binding system, and module instantiation

lastUrl = location.href
previousContext = {}
initModules = null
reapplyQueue = []

window.Page = (setup) ->
  initModules = setup || (-> {})

Page.visit = (url, opts={}) ->
  if opts.reload
    window.location = url
  else
    Turbolinks.visit(url)

Page.processMessage = (data, event) ->
  context = Bindings.context(document.querySelector('body'))
  context.processMessage?(data, event) if context

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
    Turbolinks.loadPage null, options.response, true, callback, options.onlyKeys || []
  else
    Turbolinks.visit newUrl, true, options.onlyKeys || [], -> callback?()

Page.onRefresh = (instance, nodeOrCallback, callback) ->
  if !callback then callback = nodeOrCallback else node = nodeOrCallback

  # we currently don't support refreshing contexts on page context
  return unless node

  key = Bindings.contextKey(node, instance)

  if previousInstance = previousContext[key]
    reapplyQueue.push([previousInstance, callback])

  previousContext[key] = instance

Page.pushState = (path) ->
  window.history.pushState({turbolinks: true, url: path}, null, path)

Page.replaceState = (path) ->
  window.history.replaceState({turbolinks: true, url: path}, null, path)

Page.open = ->
  window.open(arguments...)

Page.openPopup = (href, name, options) ->
  defaultOptions =
    width: 500
    height: 500
    directories: 'no'
    location: 'no'
    menubar: 'no'
    resizeable: 'yes'
    scrollbars: 'yes'
    toolbar: 'no'
    status: 'no'
  options = _.defaults(options, defaultOptions)
  optionsString = _.map(options, (v,k) -> "#{k}=#{v}").toString()
  Page.open(href, name, optionsString)

reset = (nodes) ->
  previousContext = {} if location.href != lastUrl

  if initModules?
    newContext = initModules()
    Bindings.reset(newContext)
    Bindings.bind() unless nodes
    initModules = null

  if nodes
    Bindings.bind(node) for node in nodes

  for [instance, callback] in reapplyQueue
    callback(instance)
  reapplyQueue.length = 0

  Bindings.refreshImmediately()
  newContext.pageLoaded?() if newContext
  return

document.addEventListener 'DOMContentLoaded', -> reset()

document.addEventListener 'page:load', (event) ->
  reset(event.data)
  lastUrl = location.href
  return

document.addEventListener 'page:before-partial-replace', (event) ->
  nodes = event.data
  Bindings.unbind(node) for node in nodes
  return

$(document).ajaxComplete ->
  Bindings.refresh()
