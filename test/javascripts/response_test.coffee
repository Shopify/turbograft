describe 'TurboGraft.Response', ->
  sandbox = null
  iframe = null
  baseHTML = '<html><head></head><body></body></html>'

  responseForFixture = ({fixture, intendedURL=null}, callback) ->
    xhr = new XMLHttpRequest
    xhr.open("GET", "/#{fixture}", true)
    xhr.send()
    xhr.onload = ->
      callback(new TurboGraft.Response(xhr, intendedURL))
    xhr.onerror = ->
      callback(new TurboGraft.Response(xhr, intendedURL))

  setupIframe = ->
    iframe = document.createElement('iframe')
    document.body.appendChild(iframe)
    iframe.contentDocument.write(baseHTML)
    iframe.contentDocument

  beforeEach ->
    testDocument = setupIframe() unless iframe
    Turbolinks.document(testDocument)
    sandbox = sinon.sandbox.create()
    sandbox.useFakeServer()
    Object.keys(ROUTES).forEach (url) ->
      sandbox.server.respondWith('/' + url, ROUTES[url])
    sandbox.server.autoRespond = true

  afterEach ->
    sandbox.restore()

  it 'is defined', ->
    assert(TurboGraft.Response)

  describe 'valid', ->
    it 'returns false when a server error is encountered', (done) ->
      responseForFixture { fixture: 'serverError' }, (response) ->
        assert(!response.valid(), 'response should not be valid when an error is received')
        done()

    it 'returns true when a 422 error is encountered', (done) ->
      responseForFixture { fixture: 'validationError' }, (response) ->
        assert(response.valid(), 'response should be valid when a 422 error is received')
        done()

    it 'returns true when a success status is encountered', (done) ->
      responseForFixture { fixture: 'noScriptsOrLinkInHead' }, (response) ->
        assert(response.valid(), 'response should be valid when a 200 is received')
        done()

    it 'throws an error when Content-Type is empty', (done) ->
      responseForFixture { fixture: 'noContentType' }, (response) ->
        assert.throws(response.valid)
        done()

  describe 'document', ->
    it 'returns TurboGraft.Document.create when valid', (done) ->
      stub = sandbox.stub(TurboGraft.Document, 'create', -> 'document')
      responseForFixture { fixture: 'noScriptsOrLinkInHead' }, (response) ->
        assert.equal(response.document(), 'document')
        done()

    it 'returns undefined when invalid', (done) ->
      responseForFixture { fixture: 'serverError' }, (response) ->
        assert.equal(response.document(), undefined)
        done()

  describe 'redirectedTo', ->
    it 'returns the responseURL if intendedURL is present and responseURL is different from passed in url', ->
      responseForFixture { fixture: 'noScriptsOrLinkInHead', intendedURL: 'test-url' }, (response) ->
        assert.equal(response.redirectedTo, 'noScriptsOrLinkInHead')
        done()

    it 'returns the value of the X-XHR-Redirected-To header when present', (done) ->
      responseForFixture { fixture: 'xhrRedirectedToHeader' }, (response) ->
        assert.equal(response.redirectedTo, ROUTES['xhrRedirectedToHeader'][1]['X-XHR-Redirected-To'])
        done()

  describe 'redirectedToNewUrl', ->
    beforeEach ->
      sandbox.stub(TurboGraft, 'location', -> 'test-location')

    it 'returns false when no redirect header is present', (done) ->
      responseForFixture { fixture: 'noScriptsOrLnkInHead' }, (response) ->
        assert(!response.redirectedToNewUrl(), 'response should report that it was redirected to a new url when it has no redirect header')
        done()

    it 'returns false when a redirect header is present but matches location.href', (done) ->
      responseForFixture { fixture: 'xhrRedirectedToHeader' }, (response) ->
        assert.equal(response.redirectedToNewUrl(), false)
        done()

    it 'returns true when a redirect header is present and does not match location.href', (done) ->
      responseForFixture { fixture: 'otherXhrRedirectedToHeader' }, (response) ->
        assert.equal(response.redirectedToNewUrl(), true)
        done()
