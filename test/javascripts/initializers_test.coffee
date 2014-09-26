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

    it 'does nothing when the link is disabled ', ->
      $link = $("<a partial-graft>").attr("disabled", "disabled").attr("href", "/foo").attr("refresh", "foo bar")
      $("body").append($link)
      $link[0].click()
      assert.equal 0, @refreshStub.callCount, "Refresh was called when it shouldn't have been"

    it 'works on buttons too', ->
      $button = $("<button partial-graft>").attr("href", "/foo").attr("refresh", "foo bar")
      $("body").append($button)
      $button[0].click()
      assert @refreshStub.calledWith
        url: "/foo",
        onlyKeys: ['foo', 'bar']

    it 'does nothing when the button is disabled ', ->
      $button = $("<button partial-graft>").attr("disabled", "disabled").attr("href", "/foo").attr("refresh", "foo bar")
      $("body").append($button)
      $button[0].click()
      assert.equal 0, @refreshStub.callCount, "Refresh was called when it shouldn't have been"

  describe 'remote-method', ->
    beforeEach ->
      @Remote = stub(TurboGraft, "Remote")

    afterEach ->
      @Remote.restore()

    it 'creates a remote based on the options passed in', ->
      $link = $("<a>")
        .attr("remote-method", "GET")
        .attr("refresh-on-success", "foo")
        .attr("refresh-on-error", "bar")
        .attr("href", "somewhere")

      $("body").append($link)
      $link[0].click()
      assert @Remote.calledWith
        httpRequestType: "GET"
        httpUrl: "somewhere"
        fullRefresh: false
        refreshOnSuccess: "foo"
        refreshOnError: "bar"

    it 'passes through null for missing refresh-on-success', ->
      $link = $("<a>")
        .attr("remote-method", "GET")
        .attr("refresh-on-error", "bar")
        .attr("href", "somewhere")

      $("body").append($link)
      $link[0].click()
      assert @Remote.calledWith
        httpRequestType: "GET"
        httpUrl: "somewhere"
        fullRefresh: false
        refreshOnSuccess: null
        refreshOnError: "bar"

    it 'respects remote-method supplied', ->
      $link = $("<a>")
        .attr("remote-method", "PATCH")
        .attr("refresh-on-error", "bar")
        .attr("href", "somewhere")

      $("body").append($link)
      $link[0].click()
      assert @Remote.calledWith
        httpRequestType: "PATCH"
        httpUrl: "somewhere"
        fullRefresh: false
        refreshOnSuccess: null
        refreshOnError: "bar"

    it 'passes through null for missing refresh-on-error', ->
      $link = $("<a>")
        .attr("remote-method", "GET")
        .attr("refresh-on-success", "foo")
        .attr("href", "somewhere")

      $("body").append($link)
      $link[0].click()
      assert @Remote.calledWith
        httpRequestType: "GET"
        httpUrl: "somewhere"
        fullRefresh: false
        refreshOnSuccess: "foo"
        refreshOnError: null

    it 'respects full-refresh', ->
      $link = $("<a>")
        .attr("full-refresh", true)
        .attr("remote-method", "GET")
        .attr("refresh-on-success", "foo")
        .attr("refresh-on-error", "bar")
        .attr("href", "somewhere")

      $("body").append($link)
      $link[0].click()
      assert @Remote.calledWith
        httpRequestType: "GET"
        httpUrl: "somewhere"
        fullRefresh: true
        refreshOnSuccess: "foo"
        refreshOnError: "bar"

    it 'will use a full-refresh if neither refresh-on-success nor refresh-on-error are provided', ->
      $link = $("<a>")
        .attr("remote-method", "GET")
        .attr("href", "somewhere")

      $("body").append($link)
      $link[0].click()
      assert @Remote.calledWith
        httpRequestType: "GET"
        httpUrl: "somewhere"
        fullRefresh: true
        refreshOnSuccess: null
        refreshOnError: null

    it 'does nothing if disabled', ->
      $link = $("<a>")
        .attr("disabled", "disabled")
        .attr("remote-method", "GET")
        .attr("refresh-on-success", "foo")
        .attr("refresh-on-error", "bar")
        .attr("href", "somewhere")

      $("body").append($link)
      $link[0].click()
      assert.equal 0, @Remote.callCount
