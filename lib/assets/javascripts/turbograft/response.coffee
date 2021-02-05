class TurboGraft.Response
  constructor: (@xhr, intendedURL) ->
    if intendedURL && intendedURL.withoutHash() != @xhr.responseURL
      redirectedTo = @xhr.responseURL
    else
      redirectedTo = @xhr.getResponseHeader('X-XHR-Redirected-To')

    @finalURL = redirectedTo || intendedURL

  valid: -> @hasRenderableHttpStatus() && @hasValidContent()

  document: ->
    if @valid()
      TurboGraft.Document.create(@xhr.responseText)

  hasRenderableHttpStatus: ->
    return true if 200 <= @xhr.status < 600
    false

  hasValidContent: ->
    if contentType = @xhr.getResponseHeader('Content-Type')
      contentType.match(/^(?:text\/html|application\/xhtml\+xml|application\/xml)(?:;|$)/)
    else
      throw new Error("Error encountered for XHR Response: #{this}")

  toString: () ->
    "URL: #{@xhr.responseURL}, " +
    "ReadyState: #{@xhr.readyState}, " +
    "Headers: #{@xhr.getAllResponseHeaders()}"

TurboGraft.location = () -> location.href
