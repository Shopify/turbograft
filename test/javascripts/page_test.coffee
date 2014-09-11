describe 'Page', ->
  it 'is defined', ->
    assert Page

  describe '#visit', ->
    it 'will call Turbolinks#visit without any options', ->
      visit = spy(Turbolinks, "visit")
      Page.visit("http://example.com")
      assert visit.calledOnce
