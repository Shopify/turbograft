describe 'Initializers', ->

  describe 'tg-remote on links', ->
    beforeEach ->
      @Remote = stub(TurboGraft, "Remote").returns({submit: ->})

    afterEach ->
      @Remote.restore()

    it 'creates a remote based on the options passed in', ->
      $link = $("<a>")
        .attr("tg-remote", "GET")
        .attr("refresh-on-success", "foo")
        .attr("refresh-on-error", "bar")
        .attr("full-refresh-on-error-except", "zar")
        .attr("href", "somewhere")

      $("body").append($link)
      $link[0].click()
      assert @Remote.calledWith
        httpRequestType: "GET"
        httpUrl: "somewhere"
        fullRefresh: false
        refreshOnSuccess: "foo"
        refreshOnError: "bar"
        refreshOnErrorExcept: "zar"

    it 'passes through null for missing refresh-on-success', ->
      $link = $("<a>")
        .attr("tg-remote", "GET")
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
        refreshOnErrorExcept: null

    it 'respects tg-remote supplied', ->
      $link = $("<a>")
        .attr("tg-remote", "PATCH")
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
        refreshOnErrorExcept: null

    it 'passes through null for missing refresh-on-error', ->
      $link = $("<a>")
        .attr("tg-remote", "GET")
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
        refreshOnErrorExcept: null

    it 'passes through null for missing full-refresh-on-error-except', ->
      $link = $("<a>")
        .attr("tg-remote", "GET")
        .attr("full-refresh-on-error-except", "zew")
        .attr("href", "somewhere")

      $("body").append($link)
      $link[0].click()
      assert @Remote.calledWith
        httpRequestType: "GET"
        httpUrl: "somewhere"
        fullRefresh: false
        refreshOnSuccess: null
        refreshOnError: null
        refreshOnErrorExcept: 'zew'

    it 'respects full-refresh', ->
      $link = $("<a>")
        .attr("full-refresh", true)
        .attr("tg-remote", "GET")
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
        refreshOnErrorExcept: null

    it 'does nothing if disabled', ->
      $link = $("<a>")
        .attr("disabled", "disabled")
        .attr("tg-remote", "GET")
        .attr("refresh-on-success", "foo")
        .attr("refresh-on-error", "bar")
        .attr("href", "somewhere")

      $("body").append($link)
      $link[0].click()
      assert.equal 0, @Remote.callCount

    it 'clicking on nodes inside of an <a> will bubble correctly', ->
      $link = $("<a><i>foo</i></a>")
        .attr("tg-remote", "PATCH")
        .attr("refresh-on-error", "bar")
        .attr("href", "somewhere")

      $i = $link.find("i")

      $("body").append($link)
      $i[0].click()
      assert @Remote.calledWith
        httpRequestType: "PATCH"
        httpUrl: "somewhere"
        fullRefresh: false
        refreshOnSuccess: null
        refreshOnError: "bar"
        refreshOnErrorExcept: null

      $link.remove()

    it 'clicking on nodes inside of a <button> will bubble correctly', ->
      $link = $("<a><i><em><strong>foo</strong></em></i></a>")
        .attr("tg-remote", "PATCH")
        .attr("refresh-on-error", "bar")
        .attr("href", "somewhere")

      $strong = $link.find("strong")

      $("body").append($link)
      $strong[0].click()
      assert @Remote.calledWith
        httpRequestType: "PATCH"
        httpUrl: "somewhere"
        fullRefresh: false
        refreshOnSuccess: null
        refreshOnError: "bar"
        refreshOnErrorExcept: null

      $link.remove()
