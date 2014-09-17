document.addEventListener 'click', (ev) ->
  target = ev.target
  partialGraft = target.getAttribute("partial-graft")
  href = target.getAttribute("href")
  refresh = target.getAttribute("refresh")
  return unless partialGraft != null && href != null && refresh != null

  keys = refresh.trim().split(" ")

  Page.refresh
    url: href,
    onlyKeys: keys

, true
