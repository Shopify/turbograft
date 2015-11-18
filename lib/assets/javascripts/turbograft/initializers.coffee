hasClass = (node, search) ->
  node.classList.contains(search)

nodeIsDisabled = (node) ->
   node.getAttribute('disabled') || hasClass(node, 'disabled')

setupRemoteFromTarget = (target, httpRequestType, form = null) ->
  httpUrl = target.getAttribute('href') || target.getAttribute('action')

  throw new Error("Turbograft developer error: You did not provide a URL ('data-tg-#{urlAttribute}' attribute) for data-tg-remote") unless httpUrl

  if target.getAttribute("data-tg-remote-once") || target.getAttribute("remote-once")
    target.removeAttribute("data-tg-remote-once")
    target.removeAttribute("remote-once")
    target.removeAttribute("data-tg-remote")
    target.removeAttribute("tg-remote")

  options =
    httpRequestType: httpRequestType
    httpUrl: httpUrl
    fullRefresh: target.getAttribute('data-tg-full-refresh')? || target.getAttribute('full-refresh')?
    refreshOnSuccess: target.getAttribute('data-tg-refresh-on-success') || target.getAttribute('refresh-on-success')
    refreshOnSuccessExcept: target.getAttribute('data-tg-full-refresh-on-success-except') || target.getAttribute('full-refresh-on-success-except')
    refreshOnError: target.getAttribute('data-tg-refresh-on-error') || target.getAttribute('refresh-on-error')
    refreshOnErrorExcept: target.getAttribute('data-tg-full-refresh-on-error-except') || target.getAttribute('full-refresh-on-error-except')

  new TurboGraft.Remote(options, form, target)

TurboGraft.handlers.remoteMethodHandler = (ev) ->
  target = ev.clickTarget
  httpRequestType = target.getAttribute('data-tg-remote') || target.getAttribute('tg-remote')

  return unless httpRequestType
  ev.preventDefault()

  remote = setupRemoteFromTarget(target, httpRequestType)
  remote.submit()
  return

TurboGraft.handlers.remoteFormHandler = (ev) ->
  target = ev.target
  method = target.getAttribute('method')

  return unless target.getAttribute('data-tg-remote')? || target.getAttribute('tg-remote')?
  ev.preventDefault()

  remote = setupRemoteFromTarget(target, method, target)
  remote.submit()
  return

documentListenerForButtons = (eventType, handler, useCapture = false) ->
  document.addEventListener eventType, (ev) ->
    target = ev.target

    while target != document && target?
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
