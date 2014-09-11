describe 'Page', ->

  it 'is defined', ->
    assert Page

  describe '#visit', ->
    it 'will call Turbolinks#visit without any options', ->
      visit = stub(Turbolinks, "visit")
      Page.visit("http://example.com")
      assert visit.calledOnce
      Turbolinks.visit.restore()

    it 'will just set the window.location if opts.reload', ->
      visit = stub(Turbolinks, "visit")
      Page.visit("http://example.com", {reload: true})
      assert visit.never
      Turbolinks.visit.restore()
