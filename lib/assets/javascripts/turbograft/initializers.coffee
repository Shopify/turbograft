hasClass = (node, search) ->
  node.classList.contains(search)

nodeIsDisabled = (node) ->
   node.getAttribute('disabled') || hasClass(node, 'disabled')

setupRemoteFromTarget = (target, httpRequestType, form = null) ->
  httpUrl = target.getAttribute('href') || target.getAttribute('action')

  throw new Error("Turbograft developer error: You did not provide a URL ('#{urlAttribute}' attribute) for data-tg-remote") unless httpUrl

  if TurboGraft.getTGAttribute(target, "remote-once")
    TurboGraft.removeTGAttribute(target, "remote-once")
    TurboGraft.removeTGAttribute(target, "tg-remote")

  options =
    httpRequestType: httpRequestType
    httpUrl: httpUrl
    fullRefresh: TurboGraft.getTGAttribute(target, 'full-refresh')?
    refreshOnSuccess: TurboGraft.getTGAttribute(target, 'refresh-on-success')
    refreshOnSuccessExcept: TurboGraft.getTGAttribute(target, 'full-refresh-on-success-except')
    refreshOnError: TurboGraft.getTGAttribute(target, 'refresh-on-error')
    refreshOnErrorExcept: TurboGraft.getTGAttribute(target, 'full-refresh-on-error-except')
    updatePushState: !TurboGraft.hasTGAttribute(target, 'tg-remote-nopushstate')

  new TurboGraft.Remote(options, form, target)

TurboGraft.handlers.remoteMethodHandler = (ev) ->
  target = ev.clickTarget
  httpRequestType = TurboGraft.getTGAttribute(target, 'tg-remote')

  return unless httpRequestType
  ev.preventDefault()

  remote = setupRemoteFromTarget(target, httpRequestType)
  remote.submit()
  return

TurboGraft.handlers.remoteFormHandler = (ev) ->
  target = ev.target
  method = target.getAttribute('method')

  return unless TurboGraft.hasTGAttribute(target, 'tg-remote')
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
