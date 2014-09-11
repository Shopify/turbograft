describe 'Turbolinks', ->

  html_one = """
    <!doctype html>
    <html>
      <head>
        <title>Hi there!</title>
      </head>
      <body>
        <div id="turbo-area" refresh="turbo-area">Hi bob</div>
      </body>
    </html>
  """

  it 'is defined', ->
    assert Turbolinks

  describe '#visit', ->

    it 'performs a partial page replacement with remote XHR contents', ->

      server = sinon.fakeServer.create()
      server.respondWith("GET", "/test/fixture.html",
            [200, { "Content-Type": "application/html" },
             '[{ "id": 12, "comment": "Hey there" }]']);

      some_stub = stub()
      Turbolinks.visit "/test/fixture.html", true, ['turbo-area'], some_stub

      assert.equal "Hi there!", document.title
