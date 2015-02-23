describe 'Page', ->

  beforeEach ->
    @visitStub = stub(Turbolinks, "visit")
    @replaceStateStub = stub(Turbolinks, "replaceState")

  afterEach ->
    @visitStub.restore()
    @replaceStateStub.restore()

  it 'is defined', ->
    assert Page

  describe '#visit', ->
    it 'will call Turbolinks#visit without any options', ->
      Page.visit("http://example.com")
      assert @visitStub.calledOnce

  describe '#refresh', ->
    it 'with opts.url', ->
      Page.refresh
        url: '/foo'

      assert @visitStub.calledOnce
      assert @visitStub.calledWith "/foo", {partialRefresh: true, onlyKeys: undefined}

    it 'with opts.queryParams', ->
      Page.refresh
        queryParams:
          foo: "bar"
          baz: "bot"

      assert @visitStub.calledOnce
      assert @visitStub.calledWith location.pathname + "?foo=bar&baz=bot"

    it 'ignores opts.queryParams if opts.url is present', ->
      Page.refresh
        url: '/foo'
        queryParams:
          foo: "bar"

      assert @visitStub.calledOnce
      assert @visitStub.calledWith "/foo"

    it 'uses location.href if opts.url and opts.queryParams are missing', ->
      Page.refresh()

      assert @visitStub.calledOnce
      assert @visitStub.calledWith location.href

    it 'with opts.onlyKeys', ->
      Page.refresh
        onlyKeys: ['a', 'b', 'c']

      assert @visitStub.calledOnce
      assert @visitStub.calledWith location.href, {partialRefresh: true, onlyKeys: ['a', 'b', 'c']}

    it 'with callback', ->
      afterRefreshCallback = stub()
      Page.refresh {}, afterRefreshCallback

      assert @visitStub.calledOnce
      assert @visitStub.calledWith location.href, {partialRefresh: true, callback: afterRefreshCallback}

    it 'calls Turbolinks#loadPage if an XHR is provided in opts.response', ->
      loadPageStub = stub(Turbolinks, "loadPage")
      afterRefreshCallback = stub()

      Page.refresh
        response: "placeholder for an XHR"
        onlyKeys: ['a', 'b']
      , afterRefreshCallback

      assert loadPageStub.calledOnce
      assert loadPageStub.calledWith null, "placeholder for an XHR", true, afterRefreshCallback, ['a', 'b']
      loadPageStub.restore()

    it 'updates window push state when response is a redirect', ->

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
      Page.refresh
        response: mockXHR,
        onlyKeys: ['a']

      @replaceStateStub.calledWith mockXHR.getResponseHeader('X-XHR-Redirected-To')
