class TurboGraft.Remote
  constructor: (@opts, form, target) ->

    @initiator = form || target

    @actualRequestType = if @opts.httpRequestType?.toLowerCase() == 'get' then 'GET' else 'POST'

    @formData = @createPayload(form)

    @refreshOnSuccess       = @opts.refreshOnSuccess.split(" ")       if @opts.refreshOnSuccess
    @refreshOnError         = @opts.refreshOnError.split(" ")         if @opts.refreshOnError
    @refreshOnErrorExcept   = @opts.refreshOnErrorExcept.split(" ")   if @opts.refreshOnErrorExcept

    xhr = new XMLHttpRequest
    if @actualRequestType == 'GET'
      xhr.open(@actualRequestType, @opts.httpUrl + "?#{@formData}", true)
    else
      xhr.open(@actualRequestType, @opts.httpUrl, true)
    xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest')
    xhr.setRequestHeader('Accept', 'text/html, application/xhtml+xml, application/xml')
    xhr.setRequestHeader("Content-Type", @contentType) if @contentType

    csrfToken = CSRFToken.get().token
    xhr.setRequestHeader('X-CSRF-Token', csrfToken) if csrfToken

    triggerEventFor('turbograft:remote:init', @initiator, {xhr: xhr, initiator: @initiator})

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
      @opts.done?()
      triggerEventFor 'turbograft:remote:always', @initiator,
        initiator: @initiator
        xhr: xhr

    @xhr = xhr

  submit: ->
    @xhr.send(@formData)

  createPayload: (form) ->
    if form
      if form.querySelectorAll("[type='file']").length > 0
        formData = new FormData(form)
      else # for much smaller payloads
        formData = @uriEncodeForm(form)
    else
      formData = new FormData()

    if formData instanceof FormData
      formData.append("_method", @opts.httpRequestType) if @opts.httpRequestType
    else
      @contentType = "application/x-www-form-urlencoded; charset=UTF-8"
      formData = @formAppend(formData, "_method", @opts.httpRequestType) if formData.indexOf("_method") == -1 && @opts.httpRequestType && @actualRequestType != 'GET'
      formData = formData.slice(0,-1) if formData.charAt(formData.length - 1) == "&"

    formData

  formAppend: (uriEncoded, key, value) ->
    uriEncoded += "#{encodeURIComponent(key)}=#{encodeURIComponent(value)}&"

  uriEncodeForm: (form) ->
    formData = ""
    inputs = form.querySelectorAll("input:not([type='reset']):not([type='button']):not([type='submit']):not([type='image']), select, textarea")
    for input in inputs
      inputEnabled = !input.disabled
      radioOrCheck = (input.type == 'checkbox' || input.type == 'radio')

      if inputEnabled && input.name
        if (radioOrCheck && input.checked) || !radioOrCheck
          formData = @formAppend(formData, input.name, input.value)

    formData

  onSuccess: (ev) ->
    @opts.success?()

    xhr = ev.target
    triggerEventFor 'turbograft:remote:success', @initiator,
      initiator: @initiator
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
    else
      Page.refresh
        response: xhr

  onError: (ev) ->
    @opts.fail?()

    xhr = ev.target
    triggerEventFor 'turbograft:remote:fail', @initiator,
      initiator: @initiator
      xhr: xhr

    if @refreshOnError || @refreshOnErrorExcept
      Page.refresh
        response: xhr
        onlyKeys: @refreshOnError
        exceptKeys: @refreshOnErrorExcept
    else
      triggerEventFor 'turbograft:remote:fail:unhandled', @initiator,
        xhr: xhr
