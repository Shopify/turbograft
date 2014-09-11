describe 'Turbolinks', ->

  createTurboNodule = ->
    $nodule = $("<div>").attr("id", "turbo-area").attr("refresh", "turbo-area")
    return $nodule[0]

  url_for = (slug) ->
    window.location.origin + slug

  beforeEach ->
    $("script").attr("data-turbolinks-eval", false)
    $("#mocha").attr("refresh-never", true)
    @replaceStateStub = stub(Turbolinks, "replaceState")
    @pushStateStub = stub(Turbolinks, "pushState")
    document.body.appendChild(createTurboNodule())

  afterEach ->
    @pushStateStub.restore()
    @replaceStateStub.restore()
    $("#turbo-area").remove()

  html_one = """
    <!doctype html>
    <html>
      <head>
        <title>Hi there!</title>
      </head>
      <body>
        <div>YOLO</div>
        <div id="turbo-area" refresh="turbo-area">Hi bob</div>
      </body>
    </html>
  """

  script_response = """
    <!doctype html>
    <html>
      <head>
        <title>Hi</title>
      </head>
      <body>
        <script id="turbo-area" refresh="turbo-area">globalStub()</script>
      </body>
    </html>
  """

  script_response_turbolinks_eval_false = """
    <!doctype html>
    <html>
      <head>
        <title>Hi</title>
      </head>
      <body>
        <script data-turbolinks-eval="false" id="turbo-area" refresh="turbo-area">globalStub()</script>
      </body>
    </html>
  """

  it 'is defined', ->
    assert Turbolinks

  it 'can access the property usePageCache', ->
    assert.equal false, Turbolinks.usePageCache

  it 'has a PageCache object', ->
    assert Turbolinks.pageCache
    assert.equal 0, Turbolinks.pageCache.length()

  describe '#cacheCurrentPage', ->
    it 'stores some data about our current page', ->
      assert.equal 0, Turbolinks.pageCache.length()
      Turbolinks.cacheCurrentPage()
      assert.equal 1, Turbolinks.pageCache.length()

  describe '#visit', ->
    describe 'with partial page replacement', ->
      it 'uses just the part of the response body we supply', ->

        server = sinon.fakeServer.create()
        server.respondWith([200, { "Content-Type": "text/html" }, html_one]);

        Turbolinks.visit "/some_request", true, ['turbo-area']
        server.respond()

        assert.equal "Hi there!", document.title
        assert.equal -1, document.body.textContent.indexOf("YOLO")
        assert document.body.textContent.indexOf("Hi bob") > 0
        assert @pushStateStub.calledOnce
        assert @pushStateStub.calledWith({turbolinks: true, url: url_for("/some_request")}, "", url_for("/some_request"))
        assert.equal 0, @replaceStateStub.callCount

      it 'calls a user-supplied callback', ->
        server = sinon.fakeServer.create()
        server.respondWith([200, { "Content-Type": "text/html" }, html_one]);

        your_callback = stub()
        Turbolinks.visit "/some_request", true, ['turbo-area'], your_callback
        server.respond()

        assert your_callback.calledOnce

      it 'script tags are evaluated when they are the subject of a partial replace', ->
        window.globalStub = stub()
        server = sinon.fakeServer.create()
        server.respondWith([200, { "Content-Type": "text/html" }, script_response]);

        Turbolinks.visit "/some_request", true, ['turbo-area']
        server.respond()
        assert globalStub.calledOnce

      it 'script tags are not evaluated if they have [data-turbolinks-eval="false"]', ->
        window.globalStub = stub()
        server = sinon.fakeServer.create()
        server.respondWith([200, { "Content-Type": "text/html" }, script_response_turbolinks_eval_false]);

        Turbolinks.visit "/some_request", true, ['turbo-area']
        server.respond()
        assert.equal 0, globalStub.callCount

    describe 'without partial page replacement', ->
      it 'uses entire response body', ->
        server = sinon.fakeServer.create()
        server.respondWith([200, { "Content-Type": "text/html" }, html_one]);

        Turbolinks.visit "/some_request", false, ['turbo-area']
        server.respond()

        assert.equal "Hi there!", document.title
        assert document.body.textContent.indexOf("YOLO") > 0
        assert document.body.textContent.indexOf("Hi bob") > 0
        assert @pushStateStub.calledOnce
        assert @pushStateStub.calledWith({turbolinks: true, url: url_for("/some_request")}, "", url_for("/some_request"))
        assert.equal 0, @replaceStateStub.callCount

      it 'ignores any partial refresh keys we might accidentally supply', ->
        server = sinon.fakeServer.create()
        server.respondWith([200, { "Content-Type": "text/html" }, html_one]);

        Turbolinks.visit "/some_request", false, ['turbo-area']
        server.respond()

        assert.equal "Hi there!", document.title
        assert document.body.textContent.indexOf("YOLO") > 0
        assert document.body.textContent.indexOf("Hi bob") > 0
        assert @pushStateStub.calledOnce
        assert @pushStateStub.calledWith({turbolinks: true, url: url_for("/some_request")}, "", url_for("/some_request"))
        assert.equal 0, @replaceStateStub.callCount
