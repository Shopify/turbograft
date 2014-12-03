hasClass = (node, search) ->
  node.classList.contains(search)

nodeIsDisabled = (node) ->
   node.getAttribute('disabled') || hasClass(node, 'disabled')

TurboGraft.handlers.partialGraftClickHandler = (ev) ->
  target = ev.target
  partialGraft = target.getAttribute("partial-graft")
  return unless partialGraft?
  ev.preventDefault()
  href = target.getAttribute("href")
  refresh = target.getAttribute("refresh")
  throw new Error("TurboGraft developer error: href is not defined on node #{target}") unless href?
  throw new Error("TurboGraft developer error: refresh is not defined on node #{target}") unless refresh?

  keys = refresh.trim().split(" ")

  Page.refresh
    url: href,
    onlyKeys: keys

TurboGraft.handlers.remoteMethodHandler = (ev) ->
  target = ev.target
  httpRequestType = target.getAttribute('tg-remote')
  return unless httpRequestType
  ev.preventDefault()
  httpUrl = target.getAttribute('href')
  throw new Error("Turbograft developer error: You did not provide a URL ('href' attribute) for tg-remote") unless httpUrl

  if target.getAttribute("remote-once")
    target.removeAttribute("remote-once")
    target.removeAttribute("tg-remote")

  options =
    httpRequestType: httpRequestType
    httpUrl: httpUrl
    fullRefresh: target.getAttribute('full-refresh')?
    refreshOnSuccess: target.getAttribute('refresh-on-success')
    refreshOnError: target.getAttribute('refresh-on-error')
    refreshOnErrorExcept: target.getAttribute('full-refresh-on-error-except')

  if !options.refreshOnSuccess && !options.refreshOnError && !options.refreshOnErrorExcept
    options.fullRefresh = true

  remote = new TurboGraft.Remote(options, null, target)
  remote.submit()
  return

TurboGraft.handlers.remoteFormHandler = (ev) ->
  target = ev.target
  return unless target.getAttribute('tg-remote')?
  ev.preventDefault()
  httpUrl = target.getAttribute('action')
  throw new Error("Turbograft developer error: You did not provide a URL ('action' attribute) for tg-remote") unless httpUrl

  options =
    httpUrl: httpUrl
    fullRefresh: target.getAttribute('full-refresh')?
    refreshOnSuccess: target.getAttribute('refresh-on-success')
    refreshOnError: target.getAttribute('refresh-on-error')
    refreshOnErrorExcept: target.getAttribute('full-refresh-on-error-except')

  if !options.refreshOnSuccess && !options.refreshOnError && !options.refreshOnErrorExcept
    options.fullRefresh = true

  remote = new TurboGraft.Remote(options, target, target)
  remote.submit()
  return

documentListenerForButtons = (eventType, handler, useCapture = false) ->
  document.addEventListener eventType, (ev) ->
    target = ev.target
    return if !target
    isNodeDisabled = nodeIsDisabled(target)
    ev.preventDefault() if isNodeDisabled
    return if !(target.nodeName == "A" || target.nodeName == "BUTTON") || isNodeDisabled
    handler(ev)

documentListenerForButtons('click', TurboGraft.handlers.partialGraftClickHandler, true)
documentListenerForButtons('click', TurboGraft.handlers.remoteMethodHandler, true)

document.addEventListener "submit", (ev) ->
  TurboGraft.handlers.remoteFormHandler(ev)
