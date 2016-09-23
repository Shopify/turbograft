describe 'TurboGraft.Response', ->
  sandbox = null

  responseForFixture = (fixture, callback) ->
    xhr = new XMLHttpRequest
    xhr.open("GET", "/#{fixture}", true)
    xhr.send()
    xhr.onload = ->
      callback(new TurboGraft.Response(xhr))
    xhr.onerror = ->
      callback(new TurboGraft.Response(xhr))

  beforeEach ->
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
      responseForFixture 'serverError', (response) ->
        assert(!response.valid(), 'response should not be valid when an error is received')
        done()

    it 'returns true when a 422 error is encountered', (done) ->
      responseForFixture 'validationError', (response) ->
        assert(response.valid(), 'response should be valid when a 422 error is received')
        done()

    it 'returns true when a success status is encountered', (done) ->
      responseForFixture 'noScriptsOrLinkInHead', (response) ->
        assert(response.valid(), 'response should be valid when a 200 is received')
        done()

    it 'throws an error when Content-Type is empty', (done) ->
      responseForFixture 'noContentType', (response) ->
        assert.throws(response.valid)
        done()

  describe 'document', ->
    it 'returns TurboGraft.Document.create when valid', (done) ->
      stub = sandbox.stub(TurboGraft.Document, 'create', -> 'document')
      responseForFixture 'noScriptsOrLinkInHead', (response) ->
        assert.equal(response.document(), 'document')
        done()

    it 'returns undefined when invalid', (done) ->
      responseForFixture 'serverError', (response) ->
        assert.equal(response.document(), undefined)
        done()
