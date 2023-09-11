/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
describe('Link', function() {

  beforeEach(() => Link.HTML_EXTENSIONS = ['html']); // reset

  it('parses a link', function() {
    const $a = $("<a>").attr("href", "http://example.com:90/foo/bar?query=string#yolo");
    const link = new Link($a[0]);

    assert.equal("http://example.com:90", link.origin);
    assert.equal("?query=string", link.search);
    assert.equal("http:", link.protocol);
    assert.equal("example.com:90", link.host);
    assert.equal("example.com", link.hostname);
    assert.equal(90, link.port);
    assert.equal("/foo/bar", link.pathname);
    return assert.equal("#yolo", link.hash);
  });

  describe('#_crossOrigin', function() {
    it('is false when origin is not the same', function() {
      const $a = $("<a>").attr("href", "http://example.com");
      const link = new Link($a[0]);
      return assert(link._crossOrigin());
    });

    return it('is true when origin is the same', function() {
      const $a = $("<a>").attr("href", "/foo/bar/baz");
      const link = new Link($a[0]);
      return assert(!link._crossOrigin());
    });
  });

  describe('#_anchored', function() {
    it('is true when the link is the current page location + "#"', function() {
      const $a = $("<a>").attr("href", "#");
      const link = new Link($a[0]);
      return assert(link._anchored());
    });

    return it('is true when there is a hash and the URL is the same as the current page location without its hash', function() {
      const $a = $("<a>").attr("href", "#wat");
      const link = new Link($a[0]);
      return assert(link._anchored());
    });
  });

  describe('#_nonHtml', function() {
    it('returns true if the pathname is not HTML-esque', function() {
      let $a = $("<a>").attr("href", "/sources.json");
      let link = new Link($a[0]);
      assert(link._nonHtml());

      $a = $("<a>").attr("href", "/cute-cat.jpg");
      link = new Link($a[0]);
      return assert(link._nonHtml());
    });

    it('returns false if the pathname is HTML-esque', function() {
      let $a = $("<a>").attr("href", "http://example.com");
      let link = new Link($a[0]);
      assert(!link._nonHtml());

      $a = $("<a>").attr("href", "/foo/bar/baz?query=string#yolo");
      link = new Link($a[0]);
      assert(!link._nonHtml());

      $a = $("<a>").attr("href", "/foo/bar/test.html");
      link = new Link($a[0]);
      return assert(!link._nonHtml());
    });

    return it('will return false if we add something to the extensions that should be considered HTML-esque', function() {
      const $a = $("<a>").attr("href", "/foo/bar/test.xml");
      const link = new Link($a[0]);
      assert(link._nonHtml());
      Link.allowExtensions('xml');
      return assert(!link._nonHtml());
    });
  });

  describe('#_optOut', function() {
    it('will return true if the link has a data-no-turbolink attribute', function() {
      const $a = $("<a>").attr("href", "/").attr("data-no-turbolink", "true");
      const link = new Link($a[0]);

      return assert(link._optOut());
    });

    it('will return false if the link has no parents with data-no-turbolink', function() {
      const $a = $("<a>").attr("href", "/");
      const link = new Link($a[0]);

      return assert(!link._optOut());
    });

    return it('will return true if the link has ANY ancestors with data-no-turbolink', function() {
      const $box = $("<div>").attr("data-no-turbolink", "true").append("<span>");
      const $a = $("<a>").attr("href", "/");
      $box.find("span").append($a);

      const link = new Link($box.find("a")[0]);

      return assert(link._optOut());
    });
  });

  describe('#_target', function() {
    it('will return true if there is a target attribute', function() {
      const $a = $("<a>").attr("target", "_blank");
      const link = new Link($a[0]);

      return assert(link._target());
    });

    return it('will return false if there is no target attribute', function() {
      const $a = $("<a>");
      const link = new Link($a[0]);

      return assert(!link._target());
    });
  });

  return describe('#shouldIgnore', function() {
    it('ignores cross origin links', function() {
      const $a = $("<a>").attr("href", "http://example.com");
      const link = new Link($a[0]);

      return assert(link.shouldIgnore());
    });

    it('ignores anchored links', function() {
      const $a = $("<a>").attr("href", "http://example.com#foobat");
      const link = new Link($a[0]);

      return assert(link.shouldIgnore());
    });

    it('ignores non-HTML links', function() {
      const $a = $("<a>").attr("href", "http://example.com/test.xml");
      const link = new Link($a[0]);

      return assert(link.shouldIgnore());
    });

    it('ignores opt-out links', function() {
      const $a = $("<a>").attr("href", "http://example.com#foobat").attr("data-no-turbolink", "false");
      const link = new Link($a[0]);

      return assert(link.shouldIgnore());
    });

    return it('ignores links with a target', function() {
      const $a = $("<a>").attr("href", "/").attr("target", "_blank");
      const link = new Link($a[0]);

      return assert(link.shouldIgnore());
    });
  });
});
