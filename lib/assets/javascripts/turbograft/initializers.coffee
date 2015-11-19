tgAttribute = (attr) ->
  tgAttr = if attr[0...3] == 'tg-'
    "data-#{attr}"
  else
    "data-tg-#{attr}"

getTGAttribute = (node, attr) ->
  tgAttr = tgAttribute(attr)
  node.getAttribute(tgAttr) || node.getAttribute(attr)

removeTGAttribute = (node, attr) ->
  tgAttr = tgAttribute(attr)
  node.removeAttribute(tgAttr)
  node.removeAttribute(attr)

tgAttributeExists = (node, attr) ->
  tgAttr = tgAttribute(attr)
  node.getAttribute(tgAttr)? || node.getAttribute(attr)?

hasClass = (node, search) ->
  node.classList.contains(search)

nodeIsDisabled = (node) ->
   node.getAttribute('disabled') || hasClass(node, 'disabled')

setupRemoteFromTarget = (target, httpRequestType, form = null) ->
  httpUrl = target.getAttribute('href') || target.getAttribute('action')

  throw new Error("Turbograft developer error: You did not provide a URL ('#{urlAttribute}' attribute) for data-tg-remote") unless httpUrl

  if getTGAttribute(target, "remote-once")
    removeTGAttribute(target, "remote-once")
    removeTGAttribute(target, "tg-remote")

  options =
    httpRequestType: httpRequestType
    httpUrl: httpUrl
    fullRefresh: getTGAttribute(target, 'full-refresh')?
    refreshOnSuccess: getTGAttribute(target, 'refresh-on-success')
    refreshOnSuccessExcept: getTGAttribute(target, 'full-refresh-on-success-except')
    refreshOnError: getTGAttribute(target, 'refresh-on-error')
    refreshOnErrorExcept: getTGAttribute(target, 'full-refresh-on-error-except')

  new TurboGraft.Remote(options, form, target)

TurboGraft.handlers.remoteMethodHandler = (ev) ->
  target = ev.clickTarget
  httpRequestType = getTGAttribute(target, 'tg-remote')

  return unless httpRequestType
  ev.preventDefault()

  remote = setupRemoteFromTarget(target, httpRequestType)
  remote.submit()
  return

TurboGraft.handlers.remoteFormHandler = (ev) ->
  target = ev.target
  method = target.getAttribute('method')

  return unless tgAttributeExists(target, 'tg-remote')
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
