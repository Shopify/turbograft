describe 'Initializers', ->

  describe 'partial-graft', ->
    beforeEach ->
      @refreshStub = stub(Page, "refresh")

    afterEach ->
      @refreshStub.restore()

    it 'calls Page.refresh when all required attributes are present', ->
      $link = $("<a partial-graft>").attr("href", "/foo").attr("refresh", "foo bar")
      $("body").append($link)
      $link[0].click()
      assert @refreshStub.calledWith
        url: "/foo",
        onlyKeys: ['foo', 'bar']

    it 'works on all types of node', ->
      $div = $("<div partial-graft>").attr("href", "/foo").attr("refresh", "foo bar")
      $("body").append($div)
      $div[0].click()
      assert @refreshStub.calledWith
        url: "/foo",
        onlyKeys: ['foo', 'bar']
