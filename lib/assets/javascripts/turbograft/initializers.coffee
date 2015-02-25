hasClass = (node, search) ->
  node.classList.contains(search)

nodeIsDisabled = (node) ->
   node.getAttribute('disabled') || hasClass(node, 'disabled')

setupRemoteFromTarget = (target, httpRequestType, urlAttribute, form = null) ->
  httpUrl = target.getAttribute(urlAttribute)

  throw new Error("Turbograft developer error: You did not provide a URL ('#{urlAttribute}' attribute) for tg-remote") unless httpUrl

  if target.getAttribute("remote-once")
    target.removeAttribute("remote-once")
    target.removeAttribute("tg-remote")

  options =
    httpRequestType: httpRequestType
    httpUrl: httpUrl
    fullRefresh: target.getAttribute('full-refresh')?
    refreshOnSuccess: target.getAttribute('refresh-on-success')
    refreshOnSuccessExcept: target.getAttribute('full-refresh-on-success-except')
    refreshOnError: target.getAttribute('refresh-on-error')
    refreshOnErrorExcept: target.getAttribute('full-refresh-on-error-except')

  new TurboGraft.Remote(options, form, target)

TurboGraft.handlers.remoteMethodHandler = (ev) ->
  target = ev.clickTarget
  httpRequestType = target.getAttribute('tg-remote')

  return unless httpRequestType
  ev.preventDefault()

  remote = setupRemoteFromTarget(target, httpRequestType, 'href')
  remote.submit()
  return

TurboGraft.handlers.remoteFormHandler = (ev) ->
  target = ev.target
  method = target.getAttribute('method')

  return unless target.getAttribute('tg-remote')?
  ev.preventDefault()

  remote = setupRemoteFromTarget(target, method, 'action', target)
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
