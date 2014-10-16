partialGraftClickHandler = (ev) ->
  target = ev.target
  partialGraft = target.getAttribute("partial-graft")
  return unless partialGraft?
  ev.preventDefault()
  href = target.getAttribute("href")
  refresh = target.getAttribute("refresh")
  throw "TurboGraft developer error: href is not defined on node #{target}" if !href?
  throw "TurboGraft developer error: refresh is not defined on node #{target}" if !refresh?

  keys = refresh.trim().split(" ")

  Page.refresh
    url: href,
    onlyKeys: keys

document.addEventListener 'click', partialGraftClickHandler, true
