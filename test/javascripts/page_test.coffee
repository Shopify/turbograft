describe 'Page', ->

  beforeEach ->
    @visitStub = stub(Turbolinks, "visit")

  afterEach ->
    @visitStub.restore()

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
      assert @visitStub.calledWith "/foo", true, []

    it 'with opts.queryParams', ->
      Page.refresh
        queryParams:
          foo: "bar"
          baz: "bot"

      assert @visitStub.calledOnce
      assert @visitStub.calledWith "/?foo=bar&baz=bot"

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
      assert @visitStub.calledWith location.href, true, ['a', 'b', 'c']

    it 'calls Turbolinks#loadPage if an XHR is provided in opts.response', ->
      loadPageStub = stub(Turbolinks, "loadPage")

      Page.refresh
        response: "placeholder for an XHR"
        onlyKeys: ['a', 'b']

      assert loadPageStub.calledOnce
      loadPageStub.restore()
