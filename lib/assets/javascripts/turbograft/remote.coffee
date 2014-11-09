class TurboGraft.Remote
  constructor: (@opts, form, target) ->
    formData = if form then new FormData(form) else new FormData()

    @initiator = target

    actualRequestType = if @opts.httpRequestType.toLowerCase() == 'get' then 'GET' else 'POST'

    formData.append("_method", @opts.httpRequestType)

    @refreshOnSuccess = @opts.refreshOnSuccess.split(" ") if @opts.refreshOnSuccess
    @refreshOnError = @opts.refreshOnError.split(" ") if @opts.refreshOnError

    xhr = new XMLHttpRequest
    xhr.open(actualRequestType, @opts.httpUrl, true)
    xhr.setRequestHeader('Accept', 'text/html, application/xhtml+xml, application/xml')
    triggerEvent('turbograft:remote:init', xhr: xhr)

    xhr.addEventListener 'loadstart', =>
      triggerEvent 'turbograft:remote:start',
        xhr: xhr,
        initiator: @initiator

    xhr.addEventListener 'error', @onError
    xhr.addEventListener 'load', (event) =>
      if xhr.status < 400
        @onSuccess(event)
      else
        @onError(event)

    xhr.addEventListener 'loadend', =>
      triggerEvent 'turbograft:remote:always',
        xhr: xhr,
        initiator: @initiator

    xhr.send(formData)
    xhr

  onSuccess: (ev) ->
    xhr = ev.target
    triggerEvent 'turbograft:remote:success',
      xhr: xhr,
      initiator: @initiator

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
    triggerEvent 'turbograft:remote:fail',
      xhr: xhr,
      initiator: @initiator

    if @refreshOnError
      Page.refresh
        response: xhr
        onlyKeys: @refreshOnError
    else
      triggerEvent 'turbograft:remote:fail:unhandled',
        xhr: xhr,
        initiator: @initiator
