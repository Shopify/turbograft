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
    xhr = options.response
    delete options.response
    Turbolinks.loadPage null, xhr, options
  else
    options.partialReplace = true
    options.callback = callback if callback

    Turbolinks.visit newUrl, options

Page.open = ->
  window.open(arguments...)
