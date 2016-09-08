class TurboGraft.Response
  constructor: (@xhr) ->

  valid: -> @hasRenderableHttpStatus() && @hasValidContent()

  document: ->
    if @valid()
      TurboGraft.Document.create(@xhr.responseText)

  hasRenderableHttpStatus: ->
    return true if @xhr.status == 422 # we want to render form validations
    !(400 <= @xhr.status < 600)

  hasValidContent: ->
    if contentType = @xhr.getResponseHeader('Content-Type')
      contentType.match(/^(?:text\/html|application\/xhtml\+xml|application\/xml)(?:;|$)/)
    else
      throw new Error("Error encountered for XHR Response: #{this}")

  toString: () ->
    "URL: #{@xhr.responseURL}, " +
    "ReadyState: #{@xhr.readyState}, " +
    "Headers: #{@xhr.getAllResponseHeaders()}"
