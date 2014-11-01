describe 'Remote', ->

  beforeEach ->
    $(document).off "turbograft:remote:start turbograft:remote:always turbograft:remote:success turbograft:remote:fail turbograft:remote:fail:unhandled"

  describe 'HTTP methods', ->
    it 'will send a GET with _method=GET', ->
      server = sinon.fakeServer.create();
      remote = new TurboGraft.Remote
        httpRequestType: "GET"
        httpUrl: "/foo/bar"

      request = server.requests[0]
      assert.equal "/foo/bar", request.url
      assert.equal "GET", request.method

    it 'will send a POST with _method=POST', ->
      server = sinon.fakeServer.create();
      remote = new TurboGraft.Remote
        httpRequestType: "POST"
        httpUrl: "/foo/bar"

      request = server.requests[0]
      assert.equal "/foo/bar", request.url
      assert.equal "POST", request.method

    it 'will send a POST with _method=PUT', ->
      server = sinon.fakeServer.create();
      remote = new TurboGraft.Remote
        httpRequestType: "PUT"
        httpUrl: "/foo/bar"

      request = server.requests[0]
      assert.equal "/foo/bar", request.url
      assert.equal "POST", request.method

    it 'will send a POST with _method=PATCH', ->
      server = sinon.fakeServer.create();
      remote = new TurboGraft.Remote
        httpRequestType: "PATCH"
        httpUrl: "/foo/bar"

      request = server.requests[0]
      assert.equal "/foo/bar", request.url
      assert.equal "POST", request.method

    it 'will send a POST with _method=DELETE', ->
      server = sinon.fakeServer.create();
      remote = new TurboGraft.Remote
        httpRequestType: "DELETE"
        httpUrl: "/foo/bar"

      request = server.requests[0]
      assert.equal "/foo/bar", request.url
      assert.equal "POST", request.method

  describe 'TurboGraft events', ->
    it 'will trigger turbograft:remote:start on start with the XHR as the data', (done) ->
      $(document).one "turbograft:remote:start", (ev) ->
        assert.equal "/foo/bar", ev.originalEvent.data.xhr.url
        done()

      server = sinon.fakeServer.create();
      remote = new TurboGraft.Remote
        httpRequestType: "POST"
        httpUrl: "/foo/bar"

    it 'if provided a target on creation, will provide this as data in events', (done) ->
      initiating_target = document.createElement("div")

      $(document).one "turbograft:remote:start", (ev) ->
        assert.equal "/foo/bar", ev.originalEvent.data.xhr.url
        assert.equal initiating_target, ev.originalEvent.data.initiator
        done()

      server = sinon.fakeServer.create();
      remote = new TurboGraft.Remote
        httpRequestType: "POST"
        httpUrl: "/foo/bar"
      , null, initiating_target

    it 'will trigger turbograft:remote:success on success with the XHR as the data', (done) ->
      $(document).one "turbograft:remote:fail", (ev) ->
        assert.equal true, false, "This should not have happened"

      $(document).one "turbograft:remote:success", (ev) ->
        assert.equal "/foo/bar", ev.originalEvent.data.xhr.url
        done()

      server = sinon.fakeServer.create();
      server.respondWith("POST", "/foo/bar",
            [200, { "Content-Type": "text/html" },
             '<div>Hey there</div>']);
      remote = new TurboGraft.Remote
        httpRequestType: "POST"
        httpUrl: "/foo/bar"

      server.respond()

    it 'will trigger turbograft:remote:fail on failure with the XHR as the data', (done) ->
      $(document).one "turbograft:remote:success", (ev) ->
        assert.equal true, false, "This should not have happened"

      $(document).one "turbograft:remote:fail:unhandled", (ev) ->
        assert.equal true, false, "This should not have happened"

      $(document).one "turbograft:remote:fail", (ev) ->
        assert.equal "/foo/bar", ev.originalEvent.data.xhr.url
        done()

      server = sinon.fakeServer.create();
      server.respondWith("POST", "/foo/bar",
            [422, { "Content-Type": "text/html" },
             '<div id="foo" refresh="foo">Error occured</div>']);
      remote = new TurboGraft.Remote
        httpRequestType: "POST"
        httpUrl: "/foo/bar"
        refreshOnError: "foo"

      server.respond()

    it 'will trigger turbograft:remote:fail:unhandled on failure with the XHR as the data when no refreshOnError was provided', (done) ->
      $(document).one "turbograft:remote:success", (ev) ->
        assert.equal true, false, "This should not have happened"

      $(document).one "turbograft:remote:fail:unhandled", (ev) ->
        assert.equal "/foo/bar", ev.originalEvent.data.xhr.url
        done()

      server = sinon.fakeServer.create();
      server.respondWith("POST", "/foo/bar",
            [422, { "Content-Type": "text/html" },
             '<div id="foo" refresh="foo">Error occured</div>']);
      remote = new TurboGraft.Remote
        httpRequestType: "POST"
        httpUrl: "/foo/bar"

      server.respond()

    it 'will trigger turbograft:remote:always on success with the XHR as the data', (done) ->
      $(document).one "turbograft:remote:always", (ev) ->
        assert.equal "/foo/bar", ev.originalEvent.data.xhr.url
        done()

      server = sinon.fakeServer.create();
      server.respondWith("POST", "/foo/bar",
            [200, { "Content-Type": "text/html" },
             '<div>Hey there</div>']);
      remote = new TurboGraft.Remote
        httpRequestType: "POST"
        httpUrl: "/foo/bar"

      server.respond()

    it 'will trigger turbograft:remote:always on failure with the XHR as the data', (done) ->
      $(document).one "turbograft:remote:always", (ev) ->
        assert.equal "/foo/bar", ev.originalEvent.data.xhr.url
        done()

      server = sinon.fakeServer.create();
      server.respondWith("POST", "/foo/bar",
            [500, { "Content-Type": "text/html" },
             '<div id="foo" refresh="foo">Error occured</div>']);
      remote = new TurboGraft.Remote
        httpRequestType: "POST"
        httpUrl: "/foo/bar"

      server.respond()

  describe 'Page methods triggered', ->
    beforeEach ->
      @refreshStub = stub(Page, "refresh")

    afterEach ->
      @refreshStub.restore()

    it 'XHR=200: will trigger Page.refresh using XHR and refresh-on-success', ->
      server = sinon.fakeServer.create();
      server.respondWith("POST", "/foo/bar",
            [200, { "Content-Type": "text/html" },
             '<div>Hey there</div>']);

      remote = new TurboGraft.Remote
        httpRequestType: "POST"
        httpUrl: "/foo/bar"
        refreshOnSuccess: "a b c"

      server.respond()
      assert @refreshStub.calledWith
        response: sinon.match.has('responseText', '<div>Hey there</div>')
        onlyKeys: ['a', 'b', 'c']

    it 'XHR=200: will trigger Page.refresh with refresh-on-success when full-refresh is provided', ->
      server = sinon.fakeServer.create();
      server.respondWith("POST", "/foo/bar",
            [200, { "Content-Type": "text/html" },
             '<div>Hey there</div>']);
      remote = new TurboGraft.Remote
        httpRequestType: "POST"
        httpUrl: "/foo/bar"
        refreshOnSuccess: "a b c"
        fullRefresh: true

      server.respond()

      assert @refreshStub.calledWith
        onlyKeys: ['a', 'b', 'c']

    it 'XHR=200: will trigger Page.refresh with no arguments when neither refresh-on-success nor refresh-on-error are provided', ->
      server = sinon.fakeServer.create();
      server.respondWith("POST", "/foo/bar",
            [200, { "Content-Type": "text/html" },
             '<div>Hey there</div>']);
      remote = new TurboGraft.Remote
        httpRequestType: "POST"
        httpUrl: "/foo/bar"
        fullRefresh: true

      server.respond()

      assert.equal 1, @refreshStub.callCount
      assert.equal 0, @refreshStub.args[0].length

    it 'will trigger Page.refresh using XHR and refresh-on-error', ->
      server = sinon.fakeServer.create();
      server.respondWith("POST", "/foo/bar",
            [422, { "Content-Type": "text/html" },
             '<div id="foo" refresh="foo">Error occured</div>']);
      remote = new TurboGraft.Remote
        httpRequestType: "POST"
        httpUrl: "/foo/bar"
        refreshOnError: "a b c"
        fullRefresh: true

      server.respond()

      assert @refreshStub.calledWith
        response: sinon.match.has('responseText', '<div id="foo" refresh="foo">Error occured</div>')
        onlyKeys: ['a', 'b', 'c']

    it 'will not trigger Page.refresh if no refresh-on-error is present', ->
      server = sinon.fakeServer.create();
      server.respondWith("POST", "/foo/bar",
            [422, { "Content-Type": "text/html" },
             '<div id="foo" refresh="foo">Error occured</div>']);
      remote = new TurboGraft.Remote
        httpRequestType: "POST"
        httpUrl: "/foo/bar"

      server.respond()

      assert.equal 0, @refreshStub.callCount
