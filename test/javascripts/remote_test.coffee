describe 'Remote', ->
  @initiating_target = null

  beforeEach ->
    $(document).off "turbograft:remote:start turbograft:remote:always turbograft:remote:success turbograft:remote:fail turbograft:remote:fail:unhandled"
    @initiating_target = $("<form />")[0]

  describe 'HTTP methods', ->

    it 'will send a GET with _method=GET', ->
      server = sinon.fakeServer.create();
      remote = new TurboGraft.Remote
        httpRequestType: "GET"
        httpUrl: "/foo/bar"
      , @initiating_target
      remote.submit()

      request = server.requests[0]
      assert.equal "/foo/bar", request.url
      assert.equal "GET", request.method

    it 'will send a POST with _method=POST', ->
      server = sinon.fakeServer.create();
      remote = new TurboGraft.Remote
        httpRequestType: "POST"
        httpUrl: "/foo/bar"
      , @initiating_target
      remote.submit()

      request = server.requests[0]
      assert.equal "/foo/bar", request.url
      assert.equal "POST", request.method

    it 'will send a POST with _method=PUT', ->
      server = sinon.fakeServer.create();
      remote = new TurboGraft.Remote
        httpRequestType: "PUT"
        httpUrl: "/foo/bar"
      , @initiating_target
      remote.submit()

      request = server.requests[0]
      assert.equal "/foo/bar", request.url
      assert.equal "POST", request.method

    it 'will send a POST with _method=PATCH', ->
      server = sinon.fakeServer.create();
      remote = new TurboGraft.Remote
        httpRequestType: "PATCH"
        httpUrl: "/foo/bar"
      , @initiating_target
      remote.submit()

      request = server.requests[0]
      assert.equal "/foo/bar", request.url
      assert.equal "POST", request.method

    it 'will send a POST with _method=DELETE', ->
      server = sinon.fakeServer.create();
      remote = new TurboGraft.Remote
        httpRequestType: "DELETE"
        httpUrl: "/foo/bar"
      , @initiating_target
      remote.submit()

      request = server.requests[0]
      assert.equal "/foo/bar", request.url
      assert.equal "POST", request.method

  describe 'TurboGraft events', ->

    beforeEach ->
      @refreshStub = stub(Page, "refresh")

    afterEach ->
      @refreshStub.restore()


    it 'allows turbograft:remote:init to set a header', ->
      $(@initiating_target).one "turbograft:remote:init", (event) ->
        event.originalEvent.data.xhr.setRequestHeader("X-Header", "anything")

      server = sinon.fakeServer.create()
      remote = new TurboGraft.Remote
        httpRequestType: "POST"
        httpUrl: "/foo/bar"
      , @initiating_target
      remote.submit()

      request = server.requests[0]
      assert.equal "anything", request.requestHeaders["X-Header"]

    it 'will automatically set the X-CSRF-Token header for you', ->
      $("meta[name='csrf-token']").remove()
      $fakeCsrfNode = $("<meta>").attr("name", "csrf-token").attr("content", "some-token")
      $("head").append($fakeCsrfNode)

      server = sinon.fakeServer.create()
      remote = new TurboGraft.Remote
        httpRequestType: "POST"
        httpUrl: "/foo/bar"
      , @initiating_target
      remote.submit()

      request = server.requests[0]
      assert.equal "some-token", request.requestHeaders["X-CSRF-Token"]

      $('meta[name="csrf-token"]').remove()

    it 'will trigger turbograft:remote:start on start with the XHR as the data', (done) ->
      $(@initiating_target).one "turbograft:remote:start", (ev) ->
        assert.equal "/foo/bar", ev.originalEvent.data.xhr.url
        done()

      server = sinon.fakeServer.create();
      remote = new TurboGraft.Remote
        httpRequestType: "POST"
        httpUrl: "/foo/bar"
      , @initiating_target
      remote.submit()

    it 'if provided a target on creation, will provide this as data in events', (done) ->
      $(@initiating_target).one "turbograft:remote:start", (ev, a) ->
        assert.equal "/foo/bar", ev.originalEvent.data.xhr.url
        done()

      server = sinon.fakeServer.create();
      remote = new TurboGraft.Remote
        httpRequestType: "POST"
        httpUrl: "/foo/bar"
      , @initiating_target
      remote.submit()

    it 'will trigger turbograft:remote:success on success with the XHR as the data', (done) ->
      $(@initiating_target).one "turbograft:remote:fail", (ev) ->
        assert.equal true, false, "This should not have happened"

      $(@initiating_target).one "turbograft:remote:success", (ev) ->
        assert.equal "/foo/bar", ev.originalEvent.data.xhr.url
        done()

      server = sinon.fakeServer.create();
      server.respondWith("POST", "/foo/bar",
            [200, { "Content-Type": "text/html" },
             '<div>Hey there</div>']);
      remote = new TurboGraft.Remote
        httpRequestType: "POST"
        httpUrl: "/foo/bar"
      , @initiating_target
      remote.submit()

      server.respond()

    it 'will trigger turbograft:remote:fail on failure with the XHR as the data', (done) ->
      $(@initiating_target).one "turbograft:remote:success", (ev) ->
        assert.equal true, false, "This should not have happened"

      $(@initiating_target).one "turbograft:remote:fail:unhandled", (ev) ->
        assert.equal true, false, "This should not have happened"

      $(@initiating_target).one "turbograft:remote:fail", (ev) ->
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
      , @initiating_target
      remote.submit()

      server.respond()

    it 'will trigger turbograft:remote:fail:unhandled on failure with the XHR as the data when no refreshOnError was provided', (done) ->
      $(@initiating_target).one "turbograft:remote:success", (ev) ->
        assert.equal true, false, "This should not have happened"

      $(@initiating_target).one "turbograft:remote:fail:unhandled", (ev) ->
        assert.equal "/foo/bar", ev.originalEvent.data.xhr.url
        done()

      server = sinon.fakeServer.create();
      server.respondWith("POST", "/foo/bar",
            [422, { "Content-Type": "text/html" },
             '<div id="foo" refresh="foo">Error occured</div>']);
      remote = new TurboGraft.Remote
        httpRequestType: "POST"
        httpUrl: "/foo/bar"
      , @initiating_target
      remote.submit()

      server.respond()

    it 'will trigger turbograft:remote:always on success with the XHR as the data', (done) ->
      $(@initiating_target).one "turbograft:remote:always", (ev) ->
        assert.equal "/foo/bar", ev.originalEvent.data.xhr.url
        done()

      server = sinon.fakeServer.create();
      server.respondWith("POST", "/foo/bar",
            [200, { "Content-Type": "text/html" },
             '<div>Hey there</div>']);
      remote = new TurboGraft.Remote
        httpRequestType: "POST"
        httpUrl: "/foo/bar"
      , @initiating_target
      remote.submit()

      server.respond()

    it 'will trigger turbograft:remote:always on failure with the XHR as the data', (done) ->
      $(@initiating_target).one "turbograft:remote:always", (ev) ->
        assert.equal "/foo/bar", ev.originalEvent.data.xhr.url
        done()

      server = sinon.fakeServer.create();
      server.respondWith("POST", "/foo/bar",
            [500, { "Content-Type": "text/html" },
             '<div id="foo" refresh="foo">Error occured</div>']);
      remote = new TurboGraft.Remote
        httpRequestType: "POST"
        httpUrl: "/foo/bar"
      , @initiating_target
      remote.submit()

      server.respond()

    it 'XHR=200: will trigger Page.refresh using XHR only', ->
      server = sinon.fakeServer.create();
      server.respondWith("POST", "/foo/bar",
            [200, { "Content-Type": "text/html" },
             '<div>Hey there</div>']);

      remote = new TurboGraft.Remote
        httpRequestType: "POST"
        httpUrl: "/foo/bar"
      , @initiating_target
      remote.submit()

      server.respond()
      assert @refreshStub.calledWith
        response: sinon.match.has('responseText', '<div>Hey there</div>')

    it 'XHR=200: will trigger Page.refresh using XHR and refresh-on-success', ->
      server = sinon.fakeServer.create();
      server.respondWith("POST", "/foo/bar",
            [200, { "Content-Type": "text/html" },
             '<div>Hey there</div>']);

      remote = new TurboGraft.Remote
        httpRequestType: "POST"
        httpUrl: "/foo/bar"
        refreshOnSuccess: "a b c"
      , @initiating_target
      remote.submit()

      server.respond()
      assert @refreshStub.calledWith
        response: sinon.match.has('responseText', '<div>Hey there</div>')
        onlyKeys: ['a', 'b', 'c']

    it 'XHR=200: will trigger Page.refresh using XHR and refresh-on-success-except', ->
      server = sinon.fakeServer.create();
      server.respondWith("POST", "/foo/bar",
            [200, { "Content-Type": "text/html" },
             '<div>Hey there</div>']);

      remote = new TurboGraft.Remote
        httpRequestType: "POST"
        httpUrl: "/foo/bar"
        refreshOnSuccessExcept: "a b c"
      , @initiating_target
      remote.submit()

      server.respond()
      assert @refreshStub.calledWith
        response: sinon.match.has('responseText', '<div>Hey there</div>')
        exceptKeys: ['a', 'b', 'c']

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
      , @initiating_target
      remote.submit()

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
      , @initiating_target
      remote.submit()

      server.respond()

      assert.equal 1, @refreshStub.callCount
      assert.equal 0, @refreshStub.args[0].length

    it 'XHR=200: will not trigger Page.refresh when tg-remote-norefresh is present on the initiator', ->
      server = sinon.fakeServer.create();
      server.respondWith("POST", "/foo/bar",
            [200, { "Content-Type": "text/html" },
             '<div>Hey there</div>']);

      @initiating_target.setAttribute("tg-remote-norefresh", true)
      remote = new TurboGraft.Remote
        httpRequestType: "POST"
        httpUrl: "/foo/bar"
        fullRefresh: true
      , @initiating_target
      remote.submit()

      server.respond()

      assert.equal 0, @refreshStub.callCount

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
      , @initiating_target
      remote.submit()

      server.respond()

      assert @refreshStub.calledWith
        response: sinon.match.has('responseText', '<div id="foo" refresh="foo">Error occured</div>')
        onlyKeys: ['a', 'b', 'c']

    it 'will trigger Page.refresh using XHR and refresh-on-error-except', ->
      server = sinon.fakeServer.create();
      server.respondWith("POST", "/foo/bar",
            [422, { "Content-Type": "text/html" },
             '<div id="foo" refresh="foo">Error occured</div>']);
      remote = new TurboGraft.Remote
        httpRequestType: "POST"
        httpUrl: "/foo/bar"
        refreshOnErrorExcept: "a b c"
        fullRefresh: true
      , @initiating_target
      remote.submit()

      server.respond()

      assert @refreshStub.calledWith
        response: sinon.match.has('responseText', '<div id="foo" refresh="foo">Error occured</div>')
        exceptKeys: ['a', 'b', 'c']

    it 'will not trigger Page.refresh if no refresh-on-error is present', ->
      server = sinon.fakeServer.create();
      server.respondWith("POST", "/foo/bar",
            [422, { "Content-Type": "text/html" },
             '<div id="foo" refresh="foo">Error occured</div>']);
      remote = new TurboGraft.Remote
        httpRequestType: "POST"
        httpUrl: "/foo/bar"
      , @initiating_target
      remote.submit()

      server.respond()

      assert.equal 0, @refreshStub.callCount

  describe 'serialization', ->

    it 'will create FormData by calling formDataAppend for each valid input', ->
      form = $("<form><input type='file' name='foo'><input type='text' name='bar' value='fizzbuzz'></form>")[0]

      appendSpy = sinon.spy(FormData.prototype, 'append')
      formDataAppendSpy = sinon.spy(TurboGraft.Remote.prototype, 'formDataAppend')

      remote = new TurboGraft.Remote({}, form)

      assert appendSpy.calledOnce
      assert formDataAppendSpy.calledTwice

    it 'will create FormData object if there is a file in the form', ->
      form = $("<form><input type='file' name='foo'></form>")[0]

      remote = new TurboGraft.Remote({}, form)
      assert (remote.formData instanceof FormData)

    it 'will not create FormData object if the only input does not have a name', ->
      form = $("<form><input type='file'></form>")[0]

      remote = new TurboGraft.Remote({}, form)
      assert.isFalse (remote.formData instanceof FormData)

    it 'will create FormData object but skip any input which doesnt have a name', ->
      form = $("<form><input type='file' name='foo'><input type='file'></form>")[0]

      remote = new TurboGraft.Remote({}, form)
      assert (remote.formData instanceof FormData)

    it 'will add the _method to the form if supplied in the constructor', ->
      form = $("<form></form>")[0]

      remote = new TurboGraft.Remote({httpRequestType: 'put'}, form)
      assert.equal "_method=put", remote.formData

    it 'will not override any Rails _method hidden input in the form, even if we try to using the constructor', ->
      form = $("<form method='POST'><input name='_method' value='PATCH'></form>")[0]
      # above: actual HTTP is POST, rails will interpret it as PATCH

      remote = new TurboGraft.Remote({httpRequestType: 'DELETE'}, form) # DELETE should be ignored here
      assert.equal "_method=PATCH", remote.formData

    it 'will not set _method when using FormData', ->
      form = $("<form><input type='file' name='foo'></form>")[0]

      oldFormData = window.FormData

      constructed = false
      window.FormData = class FormData
        constructor: ->
          constructed = true
          @hash = {}

        append: (key, val) ->
          @hash[key] = val

      remote = new TurboGraft.Remote({httpRequestType: 'DELETE'}, form)
      assert.equal undefined, remote.formData.hash._method
      assert.isTrue constructed

      window.FormData = oldFormData

    it 'will not add a _method if improperly supplied', ->
      form = $("<form method='POST'></form>")[0]

      remote = new TurboGraft.Remote({httpRequestType: undefined}, form)
      assert.equal "", remote.formData

    it 'will not create FormData object if there is no file in the form', ->
      form = $("<form><input type='text' name='foo' value='bar'></form>")[0]

      remote = new TurboGraft.Remote({}, form)
      assert.equal "foo=bar", remote.formData

    it 'properly URL encodes multiple fields in the form', ->
      formDesc = """
      <form>
        <input type="text" name="foo" value="bar">
        <input type="text" name="faa" value="bat">
        <input type="text" name="fii" value="bam+">
        <textarea name="textarea">this is a test</textarea>
        <input type="text" name="disabled" disabled value="disabled">
        <input type="radio" name="radio1" value="A">
        <input type="radio" name="radio1" value="B" checked>
        <input type="checkbox" name="checkbox" value="C">
        <input type="checkbox" name="checkbox" value="D" checked>
        <input type="checkbox" name="disabled2" value="checked" checked disabled>
        <select name="select1">
          <option value="a">foo</option>
          <option value="b">foo</option>
          <option value="c" selected>foo</option>
        </select>
        <input type="text" name="foobar" value="foobat">
      </form>
      """
      form = $(formDesc)[0]

      remote = new TurboGraft.Remote({}, form)
      assert.equal "foo=bar&faa=bat&fii=bam%2B&textarea=this%20is%20a%20test&radio1=B&checkbox=D&select1=c&foobar=foobat", remote.formData

    it 'will set content type on XHR properly when form is URL encoded', ->
      form = $("<form><input type='text' name='foo' value='bar'></form>")[0]

      remote = new TurboGraft.Remote({}, form)
      assert.equal "application/x-www-form-urlencoded; charset=UTF-8", remote.xhr.requestHeaders["Content-Type"]
