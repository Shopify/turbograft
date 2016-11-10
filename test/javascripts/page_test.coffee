describe 'Page', ->
  sandbox = null
  visitStub = null
  pushStateStub = null

  beforeEach ->
    sandbox = sinon.sandbox.create()
    visitStub = sandbox.stub(Turbolinks, 'visit')
    pushStateStub = sandbox.stub(Turbolinks, 'pushState')

  afterEach ->
    sandbox.restore()

  it 'is defined', ->
    assert Page

  describe '#visit', ->
    it 'will call Turbolinks#visit without any options', ->
      Page.visit("http://example.com")
      assert visitStub.calledOnce

  describe '#refresh', ->
    it 'with opts.url', ->
      Page.refresh(url: '/foo')

      assert.calledOnce(visitStub)
      assert.calledWithMatch(visitStub, "/foo", { partialReplace: true })

    it 'with opts.queryParams', ->
      Page.refresh
        queryParams:
          foo: "bar"
          baz: "bot"

      assert.calledOnce(visitStub)
      assert.calledWith(visitStub, location.pathname + "?foo=bar&baz=bot")

    it 'ignores opts.queryParams if opts.url is present', ->
      Page.refresh
        url: '/foo'
        queryParams:
          foo: "bar"

      assert.calledOnce(visitStub)
      assert.calledWith(visitStub, "/foo")

    it 'uses location.href if opts.url and opts.queryParams are missing', ->
      Page.refresh()

      assert.calledOnce(visitStub)
      assert.calledWith(visitStub, location.href)

    it 'with opts.onlyKeys', ->
      Page.refresh
        onlyKeys: ['a', 'b', 'c']

      assert.calledOnce(visitStub)
      assert.calledWithMatch(
        visitStub,
        location.href,
        { partialReplace: true, onlyKeys: ['a', 'b', 'c'] }
      )

    it 'with callback', ->
      afterRefreshCallback = stub()
      Page.refresh {}, afterRefreshCallback

      assert.calledOnce(visitStub)
      assert.calledWithMatch(
        visitStub,
        location.href,
        { partialReplace: true, callback: afterRefreshCallback }
      )

    it 'calls Turbolinks#loadPage if an XHR is provided in opts.response', ->
      loadPageStub = stub(Turbolinks, "loadPage")
      afterRefreshCallback = stub()
      xhrPlaceholder = "placeholder for an XHR"

      Page.refresh
        response: xhrPlaceholder
        onlyKeys: ['a', 'b']
      , afterRefreshCallback

      assert.calledOnce(loadPageStub)
      assert.calledWithMatch(loadPageStub,
        null,
        xhrPlaceholder,
        { onlyKeys: ['a', 'b'], partialReplace: true, callback: afterRefreshCallback }
      )
      loadPageStub.restore()

    it 'updates window push state when response is a redirect', (done) ->
      mockXHR = {
        getResponseHeader: (header) ->
          if header == 'Content-Type'
            return "text/html"
          else if header == 'X-XHR-Redirected-To'
            return "http://www.test.com/redirect"
          ""
        status: 302
        responseText: "<div>redirected</div>"
      }
      Page.refresh({
        response: mockXHR,
        onlyKeys: ['a'],
        }, ->
          assert.calledWith(
            pushStateStub,
            sinon.match.any,
            '',
            mockXHR.getResponseHeader('X-XHR-Redirected-To')
          )
          done()
      )

    it 'doesn\'t update window push state if updatePushState is false', (done) ->
      mockXHR = {
        getResponseHeader: (header) ->
          if header == 'Content-Type'
            return "text/html"
          else if header == 'X-XHR-Redirected-To'
            return "http://www.test.com/redirect"
          ""
        status: 302
        responseText: "<div>redirected</div>"
      }
      Page.refresh({
        response: mockXHR,
        onlyKeys: ['a']
        updatePushState: false,
        }, ->
          assert.notCalled(pushStateStub)
          done()
      )

  describe 'onReplace', ->

    beforeEach ->
      @fakebody = """
        <div id='fakebody'>
          <div id='foo'>
            <div id='bar'>
              <div id='foobar'></div>
            </div>
          </div>
          <div id='baz'>
            <div id='bat'></div>
          </div>
        </div>
      """
      $('body').append(@fakebody)

    afterEach ->
      $('#fakebody').remove()


    it 'calls the onReplace function only once', ->
      node = $('#foo')[0]
      refreshing = [$("#fakebody")[0]]
      callback = stub()

      Page.onReplace(node, callback)

      triggerEvent 'page:before-partial-replace', refreshing
      triggerEvent 'page:before-replace'

      assert callback.calledOnce

    it 'calls the onReplace function only once, even if someone were to mess with the number of events fired', ->
      node = $('#foo')[0]
      refreshing = [$("#fakebody")[0]]
      callback = stub()

      Page.onReplace(node, callback)

      triggerEvent 'page:before-partial-replace', refreshing
      triggerEvent 'page:before-partial-replace', refreshing
      triggerEvent 'page:before-partial-replace', refreshing
      triggerEvent 'page:before-replace'
      triggerEvent 'page:before-replace'
      triggerEvent 'page:before-replace'

      assert callback.calledOnce

    it 'throws an error not supplied enough arguments', ->
      try
        Page.onReplace()
        assert false, "Page.onReplace did not throw an exception"
      catch e
        assert.equal "Page.onReplace: Node and callback must both be specified", e.message

    it 'throws an error if onReplace is not supplied a function', ->
      try
        Page.onReplace(true, true)
        assert false, "Page.onReplace did not throw an exception"
      catch e
        assert.equal "Page.onReplace: Callback must be a function", e.message

    it 'calls the onReplace function if the replaced node is the node to which we bound', ->
      node = $('#foo')[0]
      refreshing = [node]
      callback = stub()

      Page.onReplace(node, callback)

      triggerEvent 'page:before-partial-replace', refreshing

      assert callback.calledOnce

    it 'calls the onReplace function even if it wasnt a partial refresh', ->
      node = $('#foo')[0]
      callback = stub()

      Page.onReplace(node, callback)

      triggerEvent 'page:before-replace'

      assert callback.calledOnce

    it 'calls the onReplace function only once, even if we replaced 2 nodes that are both ancestors of the node in question', ->
      node = $('#foobar')[0]
      refreshing = [$('#foo')[0], $('#bar')[0]]
      callback = stub()

      Page.onReplace(node, callback)

      triggerEvent 'page:before-partial-replace', refreshing

      assert callback.calledOnce

    it 'does not call the onReplace function if it was a parital refresh and the node did not get replaced', ->
      node = $('#foo')[0]
      refreshing = [$("#baz")[0]] # not a parent of #foo
      callback = stub()

      Page.onReplace(node, callback)

      triggerEvent 'page:before-partial-replace', refreshing
      # page:before-replace does not occur in this test scenario

      assert.equal 0, callback.callCount
