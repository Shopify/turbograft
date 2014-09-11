describe 'Turbolinks', ->

  createTurboNodule = ->
    $nodule = $("<div>").attr("id", "turbo-area").attr("refresh", "turbo-area")
    return $nodule[0]

  beforeEach ->
    @replaceStateStub = stub(Turbolinks, "replaceState")
    @pushStateStub = stub(Turbolinks, "pushState")
    document.body.appendChild(createTurboNodule())

  afterEach ->
    @pushStateStub.restore()
    @replaceStateStub.restore()
    document.getElementById("turbo-area").remove()

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

  it 'is defined', ->
    assert Turbolinks

  describe '#visit', ->

    it 'performs a partial page replacement with remote XHR contents', ->

      server = sinon.fakeServer.create()
      server.respondWith([200, { "Content-Type": "text/html" }, html_one]);

      some_stub = stub()
      Turbolinks.visit "/some_request", true, ['turbo-area'], some_stub
      server.respond()

      assert.equal "Hi there!", document.title
      assert.equal -1, document.body.textContent.indexOf("YOLO")
      assert document.body.textContent.indexOf("Hi bob") > 0
      assert.equal 1, @pushStateStub.callCount
      assert.equal 0, @replaceStateStub.callCount
