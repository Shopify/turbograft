/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
describe('Page', function() {
  let sandbox = null;
  let visitStub = null;
  let pushStateStub = null;

  beforeEach(function() {
    sandbox = sinon.sandbox.create();
    visitStub = sandbox.stub(Turbolinks, 'visit');
    return pushStateStub = sandbox.stub(Turbolinks, 'pushState');
  });

  afterEach(() => sandbox.restore());

  it('is defined', () => assert(Page));

  describe('#visit', () => it('will call Turbolinks#visit without any options', function() {
    Page.visit("http://example.com");
    return assert(visitStub.calledOnce);
  }));

  describe('#refresh', function() {
    it('with opts.url', function() {
      Page.refresh({url: '/foo'});

      assert.calledOnce(visitStub);
      return assert.calledWithMatch(visitStub, "/foo", { partialReplace: true });
    });

    it('with opts.queryParams', function() {
      Page.refresh({
        queryParams: {
          foo: "bar",
          baz: "bot"
        }
      });

      assert.calledOnce(visitStub);
      return assert.calledWith(visitStub, location.pathname + "?foo=bar&baz=bot");
    });

    it('ignores opts.queryParams if opts.url is present', function() {
      Page.refresh({
        url: '/foo',
        queryParams: {
          foo: "bar"
        }
      });

      assert.calledOnce(visitStub);
      return assert.calledWith(visitStub, "/foo");
    });

    it('uses location.href if opts.url and opts.queryParams are missing', function() {
      Page.refresh();

      assert.calledOnce(visitStub);
      return assert.calledWith(visitStub, location.href);
    });

    it('with opts.onlyKeys', function() {
      Page.refresh({
        onlyKeys: ['a', 'b', 'c']});

      assert.calledOnce(visitStub);
      return assert.calledWithMatch(
        visitStub,
        location.href,
        { partialReplace: true, onlyKeys: ['a', 'b', 'c'] }
      );
    });

    it('with callback', function() {
      const afterRefreshCallback = stub();
      Page.refresh({}, afterRefreshCallback);

      assert.calledOnce(visitStub);
      return assert.calledWithMatch(
        visitStub,
        location.href,
        { partialReplace: true, callback: afterRefreshCallback }
      );
    });

    it('calls Turbolinks#loadPage if an XHR is provided in opts.response', function() {
      const loadPageStub = stub(Turbolinks, "loadPage");
      const afterRefreshCallback = stub();
      const xhrPlaceholder = "placeholder for an XHR";

      Page.refresh({
        response: xhrPlaceholder,
        onlyKeys: ['a', 'b']
      }
      , afterRefreshCallback);

      assert.calledOnce(loadPageStub);
      assert.calledWithMatch(loadPageStub,
        null,
        xhrPlaceholder,
        { onlyKeys: ['a', 'b'], partialReplace: true, callback: afterRefreshCallback }
      );
      return loadPageStub.restore();
    });

    it('updates window push state when response is a redirect', function(done) {
      const mockXHR = {
        getResponseHeader(header) {
          if (header === 'Content-Type') {
            return "text/html";
          } else if (header === 'X-XHR-Redirected-To') {
            return "http://www.test.com/redirect";
          }
          return "";
        },
        status: 302,
        responseText: "<div>redirected</div>"
      };
      return Page.refresh({
        response: mockXHR,
        onlyKeys: ['a'],
        }, function() {
          assert.calledWith(
            pushStateStub,
            sinon.match.any,
            '',
            mockXHR.getResponseHeader('X-XHR-Redirected-To')
          );
          return done();
      });
    });

    return it('doesn\'t update window push state if updatePushState is false', function(done) {
      const mockXHR = {
        getResponseHeader(header) {
          if (header === 'Content-Type') {
            return "text/html";
          } else if (header === 'X-XHR-Redirected-To') {
            return "http://www.test.com/redirect";
          }
          return "";
        },
        status: 302,
        responseText: "<div>redirected</div>"
      };
      return Page.refresh({
        response: mockXHR,
        onlyKeys: ['a'],
        updatePushState: false,
        }, function() {
          assert.notCalled(pushStateStub);
          return done();
      });
    });
  });

  return describe('onReplace', function() {

    beforeEach(function() {
      this.fakebody = `\
<div id='fakebody'>
  <div id='foo'>
    <div id='bar'>
      <div id='foobar'></div>
    </div>
  </div>
  <div id='baz'>
    <div id='bat'></div>
  </div>
</div>\
`;
      return $('body').append(this.fakebody);
    });

    afterEach(() => $('#fakebody').remove());


    it('calls the onReplace function only once', function() {
      const node = $('#foo')[0];
      const refreshing = [$("#fakebody")[0]];
      const callback = stub();

      Page.onReplace(node, callback);

      triggerEvent('page:before-partial-replace', refreshing);
      triggerEvent('page:before-replace');

      return assert(callback.calledOnce);
    });

    it('calls the onReplace function only once, even if someone were to mess with the number of events fired', function() {
      const node = $('#foo')[0];
      const refreshing = [$("#fakebody")[0]];
      const callback = stub();

      Page.onReplace(node, callback);

      triggerEvent('page:before-partial-replace', refreshing);
      triggerEvent('page:before-partial-replace', refreshing);
      triggerEvent('page:before-partial-replace', refreshing);
      triggerEvent('page:before-replace');
      triggerEvent('page:before-replace');
      triggerEvent('page:before-replace');

      return assert(callback.calledOnce);
    });

    it('throws an error not supplied enough arguments', function() {
      try {
        Page.onReplace();
        return assert(false, "Page.onReplace did not throw an exception");
      } catch (e) {
        return assert.equal("Page.onReplace: Node and callback must both be specified", e.message);
      }
    });

    it('throws an error if onReplace is not supplied a function', function() {
      try {
        Page.onReplace(true, true);
        return assert(false, "Page.onReplace did not throw an exception");
      } catch (e) {
        return assert.equal("Page.onReplace: Callback must be a function", e.message);
      }
    });

    it('calls the onReplace function if the replaced node is the node to which we bound', function() {
      const node = $('#foo')[0];
      const refreshing = [node];
      const callback = stub();

      Page.onReplace(node, callback);

      triggerEvent('page:before-partial-replace', refreshing);

      return assert(callback.calledOnce);
    });

    it('calls the onReplace function even if it wasnt a partial refresh', function() {
      const node = $('#foo')[0];
      const callback = stub();

      Page.onReplace(node, callback);

      triggerEvent('page:before-replace');

      return assert(callback.calledOnce);
    });

    it('calls the onReplace function only once, even if we replaced 2 nodes that are both ancestors of the node in question', function() {
      const node = $('#foobar')[0];
      const refreshing = [$('#foo')[0], $('#bar')[0]];
      const callback = stub();

      Page.onReplace(node, callback);

      triggerEvent('page:before-partial-replace', refreshing);

      return assert(callback.calledOnce);
    });

    return it('does not call the onReplace function if it was a parital refresh and the node did not get replaced', function() {
      const node = $('#foo')[0];
      const refreshing = [$("#baz")[0]]; // not a parent of #foo
      const callback = stub();

      Page.onReplace(node, callback);

      triggerEvent('page:before-partial-replace', refreshing);
      // page:before-replace does not occur in this test scenario

      return assert.equal(0, callback.callCount);
    });
  });
});
