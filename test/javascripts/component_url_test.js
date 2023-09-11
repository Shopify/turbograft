/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
describe('ComponentUrl', function() {
  describe('constructor', function() {
    it('uses current location when not given a url', function() {
      const url = new ComponentUrl();
      return assert.equal(url.absolute, location.href);
    });

    it('does a noop and returns argument, if already a ComponentUrl', function() {
      const url = new ComponentUrl("http://example.com");
      const url2 = new ComponentUrl(url);

      return assert.equal(url, url2);
    });

    return it('parses the URL provided', function() {
      const url = new ComponentUrl("http://example.com:90/foo/bar?query=string#yolo");
      assert.equal("http://example.com:90", url.origin);
      assert.equal("?query=string", url.search);
      assert.equal("http:", url.protocol);
      assert.equal("example.com:90", url.host);
      assert.equal("example.com", url.hostname);
      assert.equal(90, url.port);
      assert.equal("/foo/bar", url.pathname);
      return assert.equal("#yolo", url.hash);
    });
  });

  describe('withoutHash', () => it('returns the URL without the hash', function() {
    const url = new ComponentUrl("http://yo.lo#shipit");
    return assert.equal("http://yo.lo/", url.withoutHash());
  }));

  return describe('hasNoHash', function() {
    it('returns true when there is no hash', function() {
      const url = new ComponentUrl("http://example.com");
      return assert(url.hasNoHash());
    });

    return it('returns false when there is a hash', function() {
      const url = new ComponentUrl("http://example.com#test");
      return assert(!url.hasNoHash());
    });
  });
});
