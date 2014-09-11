window.Page = (setup) ->
  initModules = setup || (-> {})

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
