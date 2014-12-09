hasClass = (node, search) ->
  node.classList.contains(search)

nodeIsDisabled = (node) ->
   node.getAttribute('disabled') || hasClass(node, 'disabled')

TurboGraft.handlers.remoteMethodHandler = (ev) ->
  target = ev.clickTarget
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

  remote = new TurboGraft.Remote(options, target, target)
  remote.submit()
  return

documentListenerForButtons = (eventType, handler, useCapture = false) ->
  document.addEventListener eventType, (ev) ->
    target = ev.target
    return if !target

    while target != document && (typeof target != "undefined")
      if target.nodeName == "A" || target.nodeName == "BUTTON"
        isNodeDisabled = nodeIsDisabled(target)
        ev.preventDefault() if isNodeDisabled
        unless isNodeDisabled
          ev.clickTarget = target
          handler(ev)
          return

      target = target.parentNode

documentListenerForButtons('click', TurboGraft.handlers.remoteMethodHandler, true)

document.addEventListener "submit", (ev) ->
  TurboGraft.handlers.remoteFormHandler(ev)
