window.TurboGraft = {
  handlers: {}
}

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
  throw new Error("TurboGraft developer error: href is not defined on node #{target}") if !href?
  throw new Error("TurboGraft developer error: refresh is not defined on node #{target}") if !refresh?

  keys = refresh.trim().split(" ")

  Page.refresh
    url: href,
    onlyKeys: keys

TurboGraft.handlers.remoteMethodHandler = (ev) ->
  target = ev.target
  return unless target.getAttribute('remote-method')
  ev.preventDefault()
  httpUrl = target.getAttribute('href')
  httpRequestType = target.getAttribute('remote-method')
  throw new Error("Turbograft developer error: You did not provide a request type for remote-method") if !httpRequestType
  throw new Error("Turbograft developer error: You did not provide a URL for remote-method") if !httpUrl

  if target.getAttribute("remote-once")
    target.removeAttribute("remote-once")
    target.removeAttribute("remote-method")

  options =
    httpRequestType: httpRequestType
    httpUrl: httpUrl
    fullRefresh: target.getAttribute('full-refresh')?
    refreshOnSuccess: target.getAttribute('refresh-on-success')
    refreshOnError: target.getAttribute('refresh-on-error')

  if !options.refreshOnSuccess && !options.refreshOnError
    options.fullRefresh = true

  remote = new TurboGraft.Remote(options, null, target)
  return

TurboGraft.handlers.remoteFormHandler = (ev) ->
  target = ev.target
  return unless target.getAttribute('remote-form')?
  ev.preventDefault()
  httpUrl = target.getAttribute('action')
  httpRequestType = target.getAttribute('method')
  throw new Error("Turbograft developer error: You did not provide a request type for remote-method") if !httpRequestType
  throw new Error("Turbograft developer error: You did not provide a URL for remote-method") if !httpUrl

  options =
    httpRequestType: httpRequestType
    httpUrl: httpUrl
    fullRefresh: target.getAttribute('full-refresh')?
    refreshOnSuccess: target.getAttribute('refresh-on-success')
    refreshOnError: target.getAttribute('refresh-on-error')

  if !options.refreshOnSuccess && !options.refreshOnError
    options.fullRefresh = true

  remote = new TurboGraft.Remote(options, target, target)
  return

documentListenerForButtons = (eventType, handler, useCapture = false) ->
  document.addEventListener eventType, (ev) ->
    target = ev.target
    ev.preventDefault() if nodeIsDisabled(target)
    return if !(target.nodeName == "A" || target.nodeName == "BUTTON") || nodeIsDisabled(target)
    handler(ev)

documentListenerForButtons('click', TurboGraft.handlers.partialGraftClickHandler, true)
documentListenerForButtons('click', TurboGraft.handlers.remoteMethodHandler, true)

document.addEventListener "submit", (ev) ->
  target = ev.target
  return unless target.getAttribute('remote-form')?
  TurboGraft.handlers.remoteFormHandler(ev)
