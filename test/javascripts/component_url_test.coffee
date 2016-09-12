describe 'ComponentUrl', ->
  describe 'constructor', ->
    it 'uses current location when not given a url', ->
      url = new ComponentUrl()
      assert.equal(url.absolute, location.href)

    it 'does a noop and returns argument, if already a ComponentUrl', ->
      url = new ComponentUrl("http://example.com")
      url2 = new ComponentUrl(url)

      assert.equal url, url2

    it 'parses the URL provided', ->
      url = new ComponentUrl("http://example.com:90/foo/bar?query=string#yolo")
      assert.equal "http://example.com:90", url.origin
      assert.equal "?query=string", url.search
      assert.equal "http:", url.protocol
      assert.equal "example.com:90", url.host
      assert.equal "example.com", url.hostname
      assert.equal 90, url.port
      assert.equal "/foo/bar", url.pathname
      assert.equal "#yolo", url.hash

  describe 'withoutHash', ->
    it 'returns the URL without the hash', ->
      url = new ComponentUrl("http://yo.lo#shipit")
      assert.equal "http://yo.lo/", url.withoutHash()

  describe 'hasNoHash', ->
    it 'returns true when there is no hash', ->
      url = new ComponentUrl("http://example.com")
      assert url.hasNoHash()

    it 'returns false when there is a hash', ->
      url = new ComponentUrl("http://example.com#test")
      assert !url.hasNoHash()
