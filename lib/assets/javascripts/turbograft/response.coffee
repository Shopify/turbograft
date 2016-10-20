class TurboGraft.Response
  constructor: (@xhr, intendedURL) ->
    if intendedURL && intendedURL != @xhr.responseURL
      @redirectedTo = @xhr.responseURL
    else
      @redirectedTo = @xhr.getResponseHeader('X-XHR-Redirected-To')

    @url = @redirectedTo || intendedURL

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

  redirectedToNewUrl: () ->
    Boolean(
      @redirectedTo &&
      @redirectedTo != TurboGraft.location()
    )

  toString: () ->
    "URL: #{@xhr.responseURL}, " +
    "ReadyState: #{@xhr.readyState}, " +
    "Headers: #{@xhr.getAllResponseHeaders()}"

TurboGraft.location = () -> location.href
