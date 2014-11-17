class TurboGraft.Remote
  constructor: (@opts, form, target) ->
    formData = if form then new FormData(form) else new FormData()

    @initiator = target

    actualRequestType = if @opts.httpRequestType.toLowerCase() == 'get' then 'GET' else 'POST'

    formData.append("_method", @opts.httpRequestType)

    @refreshOnSuccess       = @opts.refreshOnSuccess.split(" ")       if @opts.refreshOnSuccess
    @refreshOnError         = @opts.refreshOnError.split(" ")         if @opts.refreshOnError
    @refreshOnErrorExcept   = @opts.refreshOnErrorExcept.split(" ")   if @opts.refreshOnErrorExcept

    xhr = new XMLHttpRequest
    xhr.open(actualRequestType, @opts.httpUrl, true)
    xhr.setRequestHeader('Accept', 'text/html, application/xhtml+xml, application/xml')
    triggerEvent('turbograft:remote:init', xhr: xhr)

    xhr.addEventListener 'loadstart', =>
      triggerEventFor 'turbograft:remote:start', @initiator,
        xhr: xhr

    xhr.addEventListener 'error', @onError
    xhr.addEventListener 'load', (event) =>
      if xhr.status < 400
        @onSuccess(event)
      else
        @onError(event)

    xhr.addEventListener 'loadend', =>
      triggerEventFor 'turbograft:remote:always', @initiator,
        xhr: xhr

    xhr.send(formData)
    xhr

  onSuccess: (ev) ->
    xhr = ev.target
    triggerEventFor 'turbograft:remote:success', @initiator,
      xhr: xhr

    if redirect = xhr.getResponseHeader('X-Next-Redirect')
      Page.visit(redirect, reload: true)
      return

    if @opts.fullRefresh && @refreshOnSuccess
      Page.refresh(onlyKeys: @refreshOnSuccess)
    else if @opts.fullRefresh
      Page.refresh()
    else if @refreshOnSuccess
      Page.refresh
        response: xhr
        onlyKeys: @refreshOnSuccess

  onError: (ev) ->
    xhr = ev.target
    triggerEventFor 'turbograft:remote:fail', @initiator,
      xhr: xhr

    if @refreshOnError || @refreshOnErrorExcept
      Page.refresh
        response: xhr
        onlyKeys: @refreshOnError
        exceptKeys: @refreshOnErrorExcept
    else
      triggerEventFor 'turbograft:remote:fail:unhandled', @initiator,
        xhr: xhr
