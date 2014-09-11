describe 'Link', ->

  beforeEach ->
    Link.HTML_EXTENSIONS = ['html'] # reset

  it 'parses a link', ->
    $a = $("<a>").attr("href", "http://example.com:90/foo/bar?query=string#yolo")
    link = new Link($a[0])

    assert.equal "http://example.com:90", link.origin
    assert.equal "?query=string", link.search
    assert.equal "http:", link.protocol
    assert.equal "example.com:90", link.host
    assert.equal "example.com", link.hostname
    assert.equal 90, link.port
    assert.equal "/foo/bar", link.pathname
    assert.equal "#yolo", link.hash

  describe '#_crossOrigin', ->
    it 'is false when origin is not the same', ->
      $a = $("<a>").attr("href", "http://example.com")
      link = new Link($a[0])
      assert link._crossOrigin()

    it 'is true when origin is the same', ->
      $a = $("<a>").attr("href", "/foo/bar/baz")
      link = new Link($a[0])
      assert !link._crossOrigin()

  describe '#_anchored', ->
    it 'is true when the link is the current page location + "#"', ->
      $a = $("<a>").attr("href", "#")
      link = new Link($a[0])
      assert link._anchored()

    it 'is true when there is a hash and the URL is the same as the current page location without its hash', ->
      $a = $("<a>").attr("href", "#wat")
      link = new Link($a[0])
      assert link._anchored()

  describe '#_nonHtml', ->
    it 'returns true if the pathname is not HTML-esque', ->
      $a = $("<a>").attr("href", "/sources.json")
      link = new Link($a[0])
      assert link._nonHtml()

      $a = $("<a>").attr("href", "/cute-cat.jpg")
      link = new Link($a[0])
      assert link._nonHtml()

    it 'returns false if the pathname is HTML-esque', ->
      $a = $("<a>").attr("href", "http://example.com")
      link = new Link($a[0])
      assert !link._nonHtml()

      $a = $("<a>").attr("href", "/foo/bar/baz?query=string#yolo")
      link = new Link($a[0])
      assert !link._nonHtml()

      $a = $("<a>").attr("href", "/foo/bar/test.html")
      link = new Link($a[0])
      assert !link._nonHtml()

    it 'will return false if we add something to the extensions that should be considered HTML-esque', ->
      $a = $("<a>").attr("href", "/foo/bar/test.xml")
      link = new Link($a[0])
      assert link._nonHtml()
      Link.allowExtensions('xml')
      assert !link._nonHtml()

  describe '#_optOut', ->
    it 'will return true if the link has a data-no-turbolink attribute', ->
      $a = $("<a>").attr("href", "/").attr("data-no-turbolink", "true")
      link = new Link($a[0])

      assert link._optOut()

    it 'will return false if the link has no parents with data-no-turbolink', ->
      $a = $("<a>").attr("href", "/")
      link = new Link($a[0])

      assert !link._optOut()

    it 'will return true if the link has ANY ancestors with data-no-turbolink', ->
      $box = $("<div>").attr("data-no-turbolink", "true").append("<span>")
      $a = $("<a>").attr("href", "/")
      $box.find("span").append($a)

      link = new Link($box.find("a")[0])

      assert link._optOut()

  describe '#_target', ->
    it 'will return true if there is a target attribute', ->
      $a = $("<a>").attr("target", "_blank")
      link = new Link($a[0])

      assert link._target()

    it 'will return false if there is no target attribute', ->
      $a = $("<a>")
      link = new Link($a[0])

      assert !link._target()

  describe '#shouldIgnore', ->
    it 'ignores cross origin links', ->
      $a = $("<a>").attr("href", "http://example.com")
      link = new Link($a[0])

      assert link.shouldIgnore()

    it 'ignores anchored links', ->
      $a = $("<a>").attr("href", "http://example.com#foobat")
      link = new Link($a[0])

      assert link.shouldIgnore()

    it 'ignores non-HTML links', ->
      $a = $("<a>").attr("href", "http://example.com/test.xml")
      link = new Link($a[0])

      assert link.shouldIgnore()

    it 'ignores opt-out links', ->
      $a = $("<a>").attr("href", "http://example.com#foobat").attr("data-no-turbolink", "false")
      link = new Link($a[0])

      assert link.shouldIgnore()

    it 'ignores links with a target', ->
      $a = $("<a>").attr("href", "/").attr("target", "_blank")
      link = new Link($a[0])

      assert link.shouldIgnore()
