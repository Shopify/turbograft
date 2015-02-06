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
      url = if @formData then @opts.httpUrl + "?#{@formData}" else @opts.httpUrl
      xhr.open(@actualRequestType, url, true)
    else
      xhr.open(@actualRequestType, @opts.httpUrl, true)
    xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest')
    xhr.setRequestHeader('Accept', 'text/html, application/xhtml+xml, application/xml')
    xhr.setRequestHeader("Content-Type", @contentType) if @contentType
    xhr.setRequestHeader 'X-XHR-Referer', document.location.href

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
      if form.querySelectorAll("[type='file'][name]").length > 0
        formData = @nativeEncodeForm(form)
      else # for much smaller payloads
        formData = @uriEncodeForm(form)
    else
      formData = ''

    if formData not instanceof FormData
      @contentType = "application/x-www-form-urlencoded; charset=UTF-8"
      formData = @formAppend(formData, "_method", @opts.httpRequestType) if formData.indexOf("_method") == -1 && @opts.httpRequestType && @actualRequestType != 'GET'

    formData

  formAppend: (uriEncoded, key, value) ->
    uriEncoded += "&" if uriEncoded.length
    uriEncoded += "#{encodeURIComponent(key)}=#{encodeURIComponent(value)}"

  uriEncodeForm: (form) ->
    formData = ""
    @_iterateOverFormInputs form, (input) =>
      formData = @formAppend(formData, input.name, input.value)
    formData

  formDataAppend: (formData, input) ->
    if input.type == 'file'
      for file in input.files
        formData.append(input.name, file)
    else
      formData.append(input.name, input.value)
    formData

  nativeEncodeForm: (form) ->
    formData = new FormData
    @_iterateOverFormInputs form, (input) =>
      formData = @formDataAppend(formData, input)
    formData

  _iterateOverFormInputs: (form, callback) ->
    inputs = form.querySelectorAll("input:not([type='reset']):not([type='button']):not([type='submit']):not([type='image']), select, textarea")
    for input in inputs
      inputEnabled = !input.disabled
      radioOrCheck = (input.type == 'checkbox' || input.type == 'radio')

      if inputEnabled && input.name
        if (radioOrCheck && input.checked) || !radioOrCheck
          callback(input)

  onSuccess: (ev) ->
    @opts.success?()

    xhr = ev.target
    triggerEventFor 'turbograft:remote:success', @initiator,
      initiator: @initiator
      xhr: xhr

    if redirect = xhr.getResponseHeader('X-Next-Redirect')
      Page.visit(redirect, reload: true)
      return

    unless @initiator.hasAttribute('tg-remote-norefresh')
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
