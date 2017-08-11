describe 'Initializers', ->

  # can't figure out why this doesn't work:
  describe 'tg-remote on forms', ->
    beforeEach ->
      @Remote = stub(TurboGraft, "Remote").returns({submit: ->})

    afterEach ->
      @Remote.restore()

    it 'creates a remote based on the options passed in', ->
      $form = $("<form>")
        .attr("tg-remote", "true")
        .attr("method", "put")
        .attr("refresh-on-success", "foo")
        .attr("refresh-on-error", "bar")
        .attr("full-refresh-on-error-except", "zar")
        .attr("full-refresh-on-success-except", "zap")
        .attr("action", "somewhere")
      $form.append("<input type='submit'>")

      $("body").append($form)
      $form.find("input").trigger("click")

      assert.called(@Remote)
      assert.calledWith(@Remote,
        httpRequestType: "put"
        httpUrl: "somewhere"
        fullRefresh: false
        refreshOnSuccess: "foo"
        refreshOnSuccessExcept: "zap"
        refreshOnError: "bar"
        refreshOnErrorExcept: "zar"
        updatePushState: true
      )
      $form.remove()

    it 'passes through updatePushState=false if tg-remote-nopushstate', ->
      $form = $("<form>")
        .attr("tg-remote", "true")
        .attr("method", "put")
        .attr("refresh-on-success", "foo")
        .attr("refresh-on-error", "bar")
        .attr("full-refresh-on-error-except", "zar")
        .attr("full-refresh-on-success-except", "zap")
        .attr("tg-remote-nopushstate", "")
        .attr("action", "somewhere")
      $form.append("<input type='submit'>")

      $("body").append($form)
      $form.find("input").trigger("click")

      assert.called(@Remote)
      assert.calledWith(@Remote,
        httpRequestType: "put"
        httpUrl: "somewhere"
        fullRefresh: false
        refreshOnSuccess: "foo"
        refreshOnSuccessExcept: "zap"
        refreshOnError: "bar"
        refreshOnErrorExcept: "zar"
        updatePushState: false
      )
      $form.remove()

  describe 'tg-remote on links', ->
    beforeEach ->
      @Remote = stub(TurboGraft, "Remote").returns({submit: ->})

    afterEach ->
      @Remote.restore()

    it 'creates a remote based on the options passed in', ->
      $link = $('<a>')
        .attr('tg-remote', 'GET')
        .attr('refresh-on-success', 'foo')
        .attr('refresh-on-error', 'bar')
        .attr('full-refresh-on-error-except', 'zar')
        .attr('full-refresh-on-success-except', 'zap')
        .attr('href', 'somewhere')

      $('body').append($link)
      $link[0].click()
      assert.called(@Remote)
      assert.calledWith(@Remote,
        httpRequestType: 'GET'
        httpUrl: 'somewhere'
        fullRefresh: false
        refreshOnSuccess: 'foo'
        refreshOnSuccessExcept: 'zap'
        refreshOnError: 'bar'
        refreshOnErrorExcept: 'zar'
        updatePushState: true
      )

    it 'passes through null for missing refresh-on-success', ->
      $link = $("<a>")
        .attr("tg-remote", "GET")
        .attr("refresh-on-error", "bar")
        .attr("href", "somewhere")

      $("body").append($link)
      $link[0].click()
      assert.called(@Remote)
      assert.calledWith(@Remote,
        httpRequestType: "GET"
        httpUrl: "somewhere"
        fullRefresh: false
        refreshOnSuccess: null
        refreshOnSuccessExcept: null
        refreshOnError: "bar"
        refreshOnErrorExcept: null
        updatePushState: true
      )

    it 'respects tg-remote supplied', ->
      $link = $("<a>")
        .attr("tg-remote", "PATCH")
        .attr("refresh-on-error", "bar")
        .attr("href", "somewhere")

      $("body").append($link)
      $link[0].click()
      assert.called(@Remote)
      assert.calledWith(@Remote,
        httpRequestType: "PATCH"
        httpUrl: "somewhere"
        fullRefresh: false
        refreshOnSuccess: null
        refreshOnSuccessExcept: null
        refreshOnError: "bar"
        refreshOnErrorExcept: null
        updatePushState: true
      )

    it 'passes through null for missing refresh-on-error', ->
      $link = $("<a>")
        .attr("tg-remote", "GET")
        .attr("refresh-on-success", "foo")
        .attr("href", "somewhere")

      $("body").append($link)
      $link[0].click()
      assert.called(@Remote)
      assert.calledWith(@Remote,
        httpRequestType: "GET"
        httpUrl: "somewhere"
        fullRefresh: false
        refreshOnSuccess: "foo"
        refreshOnSuccessExcept: null
        refreshOnError: null
        refreshOnErrorExcept: null
        updatePushState: true
      )

    it 'passes through null for missing full-refresh-on-error-except', ->
      $link = $("<a>")
        .attr("tg-remote", "GET")
        .attr("full-refresh-on-error-except", "zew")
        .attr("href", "somewhere")

      $("body").append($link)
      $link[0].click()
      assert.called(@Remote)
      assert.calledWith(@Remote,
        httpRequestType: "GET"
        httpUrl: "somewhere"
        fullRefresh: false
        refreshOnSuccess: null
        refreshOnSuccessExcept: null
        refreshOnError: null
        refreshOnErrorExcept: 'zew'
        updatePushState: true
      )

    it 'passes through updatePushState=false if tg-remote-nopushstate', ->
      $link = $("<a>")
        .attr("tg-remote", "GET")
        .attr("refresh-on-success", "foo")
        .attr("href", "somewhere")
        .attr("tg-remote-nopushstate", "")

      $("body").append($link)
      $link[0].click()
      assert.called(@Remote)
      assert.calledWith(@Remote,
        httpRequestType: "GET"
        httpUrl: "somewhere"
        fullRefresh: false
        refreshOnSuccess: "foo"
        refreshOnSuccessExcept: null
        refreshOnError: null
        refreshOnErrorExcept: null
        updatePushState: false
      )

    it 'respects full-refresh-on-success-except', ->
      $link = $("<a>")
        .attr("tg-remote", "GET")
        .attr("full-refresh-on-success-except", "zew")
        .attr("href", "somewhere")

      $("body").append($link)
      $link[0].click()
      assert.called(@Remote)
      assert.calledWith(@Remote,
        httpRequestType: "GET"
        httpUrl: "somewhere"
        fullRefresh: false
        refreshOnSuccess: null
        refreshOnSuccessExcept: 'zew'
        refreshOnError: null
        refreshOnErrorExcept: null
        updatePushState: true
      )

    it 'respects full-refresh', ->
      $link = $("<a>")
        .attr("full-refresh", true)
        .attr("tg-remote", "GET")
        .attr("refresh-on-success", "foo")
        .attr("refresh-on-error", "bar")
        .attr("href", "somewhere")

      $("body").append($link)
      $link[0].click()
      assert.called(@Remote)
      assert.calledWith(@Remote,
        httpRequestType: "GET"
        httpUrl: "somewhere"
        fullRefresh: true
        refreshOnSuccess: "foo"
        refreshOnSuccessExcept: null
        refreshOnError: "bar"
        refreshOnErrorExcept: null
        updatePushState: true
      )

    it 'does nothing if disabled', ->
      $link = $("<a>")
        .attr("disabled", "disabled")
        .attr("tg-remote", "GET")
        .attr("refresh-on-success", "foo")
        .attr("refresh-on-error", "bar")
        .attr("href", "somewhere")

      $("body").append($link)
      $link[0].click()
      assert.notCalled(@Remote)

    it 'clicking on nodes inside of an <a> will bubble correctly', ->
      $link = $("<a><i>foo</i></a>")
        .attr("tg-remote", "PATCH")
        .attr("refresh-on-error", "bar")
        .attr("href", "somewhere")

      $i = $link.find("i")

      $("body").append($link)
      $i[0].click()
      assert.called(@Remote)
      assert.calledWith(@Remote,
        httpRequestType: "PATCH"
        httpUrl: "somewhere"
        fullRefresh: false
        refreshOnSuccess: null
        refreshOnSuccessExcept: null
        refreshOnError: "bar"
        refreshOnErrorExcept: null
        updatePushState: true
      )

      $link.remove()

    it 'clicking on nodes inside of a <button> will bubble correctly', ->
      $link = $("<a><i><em><strong>foo</strong></em></i></a>")
        .attr("tg-remote", "PATCH")
        .attr("refresh-on-error", "bar")
        .attr("href", "somewhere")

      $strong = $link.find("strong")

      $("body").append($link)
      $strong[0].click()
      assert.called(@Remote)
      assert.calledWith(@Remote,
        httpRequestType: "PATCH"
        httpUrl: "somewhere"
        fullRefresh: false
        refreshOnSuccess: null
        refreshOnSuccessExcept: null
        refreshOnError: "bar"
        refreshOnErrorExcept: null
        updatePushState: true
      )

      $link.remove()
