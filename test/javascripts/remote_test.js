/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const baseHTML = '<html><head></head><body></body></html>';
let iframe = null;

const setupIframe = function() {
  iframe = document.createElement('iframe');
  document.body.appendChild(iframe);
  iframe.contentDocument.write(baseHTML);
  return iframe.contentDocument;
};

describe('Remote', function() {
  this.initiating_target = null;

  beforeEach(function() {
    const testDocument = setupIframe();
    Turbolinks.document(testDocument);
    $(document).off("turbograft:remote:start turbograft:remote:always turbograft:remote:success turbograft:remote:fail turbograft:remote:fail:unhandled");
    return this.initiating_target = $("<form />")[0];});

  describe('HTTP methods', function() {
    it('will send a GET with _method=GET', function() {
      const server = sinon.fakeServer.create();
      const remote = new TurboGraft.Remote({
        httpRequestType: "GET",
        httpUrl: "/foo/bar"
      }
      , this.initiating_target);
      remote.submit();

      const request = server.requests[0];
      assert.equal("/foo/bar", request.url);
      return assert.equal("GET", request.method);
    });

    it('will send a POST with _method=POST', function() {
      const server = sinon.fakeServer.create();
      const remote = new TurboGraft.Remote({
        httpRequestType: "POST",
        httpUrl: "/foo/bar"
      }
      , this.initiating_target);
      remote.submit();

      const request = server.requests[0];
      assert.equal("/foo/bar", request.url);
      return assert.equal("POST", request.method);
    });

    it('will send a POST with _method=PUT', function() {
      const server = sinon.fakeServer.create();
      const remote = new TurboGraft.Remote({
        httpRequestType: "PUT",
        httpUrl: "/foo/bar"
      }
      , this.initiating_target);
      remote.submit();

      const request = server.requests[0];
      assert.equal("/foo/bar", request.url);
      return assert.equal("POST", request.method);
    });

    it('will send a POST with _method=PATCH', function() {
      const server = sinon.fakeServer.create();
      const remote = new TurboGraft.Remote({
        httpRequestType: "PATCH",
        httpUrl: "/foo/bar"
      }
      , this.initiating_target);
      remote.submit();

      const request = server.requests[0];
      assert.equal("/foo/bar", request.url);
      return assert.equal("POST", request.method);
    });

    return it('will send a POST with _method=DELETE', function() {
      const server = sinon.fakeServer.create();
      const remote = new TurboGraft.Remote({
        httpRequestType: "DELETE",
        httpUrl: "/foo/bar"
      }
      , this.initiating_target);
      remote.submit();

      const request = server.requests[0];
      assert.equal("/foo/bar", request.url);
      return assert.equal("POST", request.method);
    });
  });

  describe('callbacks', function() {
    it('will call options.fail() on HTTP failures', function(done) {
      const server = sinon.fakeServer.create();
      server.respondWith("POST", "/foo/bar",
            [422, { "Content-Type": "text/html" },
             '<div id="foo" refresh="foo">Error occured</div>']);
      const remote = new TurboGraft.Remote({
        httpRequestType: "POST",
        httpUrl: "/foo/bar",
        refreshOnError: "foo",
        fail: done
      }
      , this.initiating_target);
      remote.submit();

      return server.respond();
    });

    it('will call options.fail() on XHR failures', function(done) {
      const xhr = sinon.useFakeXMLHttpRequest();

      const remote = new TurboGraft.Remote({
        httpRequestType: "POST",
        httpUrl: "/foo/bar",
        refreshOnError: "foo",
        fail: done
      }
      , this.initiating_target);

      return remote.xhr.respond(404);
    });

    return it('will call options.success() on success', function(done) {
      const server = sinon.fakeServer.create();
      server.respondWith("POST", "/foo/bar",
            [200, { "Content-Type": "text/html" },
             '<div>Hey there</div>']);
      const remote = new TurboGraft.Remote({
        httpRequestType: "POST",
        httpUrl: "/foo/bar",
        refreshOnError: "foo",
        success: done
      }
      , this.initiating_target);
      remote.submit();

      return server.respond();
    });
  });

  describe('TurboGraft events', function() {
    beforeEach(function() {
      return this.refreshStub = stub(Page, "refresh");
    });

    afterEach(function() {
      return this.refreshStub.restore();
    });

    it('allows turbograft:remote:init to set a header', function() {
      $(this.initiating_target).one("turbograft:remote:init", event => event.originalEvent.data.xhr.setRequestHeader("X-Header", "anything"));

      const server = sinon.fakeServer.create();
      const remote = new TurboGraft.Remote({
        httpRequestType: "POST",
        httpUrl: "/foo/bar"
      }
      , this.initiating_target);
      remote.submit();

      const request = server.requests[0];
      return assert.equal("anything", request.requestHeaders["X-Header"]);
  });

    it('will automatically set the X-CSRF-Token header for you', function() {
      $("meta[name='csrf-token']").remove();
      const $fakeCsrfNode = $("<meta>").attr("name", "csrf-token").attr("content", "some-token");
      $("head").append($fakeCsrfNode);

      const server = sinon.fakeServer.create();
      const remote = new TurboGraft.Remote({
        httpRequestType: "POST",
        httpUrl: "/foo/bar"
      }
      , this.initiating_target);
      remote.submit();

      const request = server.requests[0];
      assert.equal("some-token", request.requestHeaders["X-CSRF-Token"]);

      return $('meta[name="csrf-token"]').remove();
    });

    it('will trigger turbograft:remote:start on start with the XHR as the data', function(done) {
      $(this.initiating_target).one("turbograft:remote:start", function(ev) {
        assert.equal("/foo/bar", ev.originalEvent.data.xhr.url);
        return done();
      });

      const server = sinon.fakeServer.create();
      const remote = new TurboGraft.Remote({
        httpRequestType: "POST",
        httpUrl: "/foo/bar"
      }
      , this.initiating_target);
      return remote.submit();
    });

    it('if provided a target on creation, will provide this as data in events', function(done) {
      $(this.initiating_target).one("turbograft:remote:start", function(ev, a) {
        assert.equal("/foo/bar", ev.originalEvent.data.xhr.url);
        return done();
      });

      const server = sinon.fakeServer.create();
      const remote = new TurboGraft.Remote({
        httpRequestType: "POST",
        httpUrl: "/foo/bar"
      }
      , this.initiating_target);
      return remote.submit();
    });

    it('will trigger turbograft:remote:success on success with the XHR as the data', function(done) {
      $(this.initiating_target).one("turbograft:remote:fail", ev => assert.equal(true, false, "This should not have happened"));

      $(this.initiating_target).one("turbograft:remote:success", function(ev) {
        assert.equal("/foo/bar", ev.originalEvent.data.xhr.url);
        return done();
      });

      const server = sinon.fakeServer.create();
      server.respondWith("POST", "/foo/bar",
            [200, { "Content-Type": "text/html" },
             '<div>Hey there</div>']);
      const remote = new TurboGraft.Remote({
        httpRequestType: "POST",
        httpUrl: "/foo/bar"
      }
      , this.initiating_target);
      remote.submit();

      return server.respond();
    });

    it('will trigger turbograft:remote:fail on failure with the XHR as the data', function(done) {
      $(this.initiating_target).one("turbograft:remote:success", ev => assert.equal(true, false, "This should not have happened"));

      $(this.initiating_target).one("turbograft:remote:fail:unhandled", ev => assert.equal(true, false, "This should not have happened"));

      $(this.initiating_target).one("turbograft:remote:fail", function(ev) {
        assert.equal("/foo/bar", ev.originalEvent.data.xhr.url);
        return done();
      });

      const server = sinon.fakeServer.create();
      server.respondWith("POST", "/foo/bar",
            [422, { "Content-Type": "text/html" },
             '<div id="foo" refresh="foo">Error occured</div>']);
      const remote = new TurboGraft.Remote({
        httpRequestType: "POST",
        httpUrl: "/foo/bar",
        refreshOnError: "foo"
      }
      , this.initiating_target);
      remote.submit();

      return server.respond();
    });

    it('will trigger turbograft:remote:fail:unhandled on failure with the XHR as the data when no refreshOnError was provided', function(done) {
      $(this.initiating_target).one("turbograft:remote:success", ev => assert.equal(true, false, "This should not have happened"));

      $(this.initiating_target).one("turbograft:remote:fail:unhandled", function(ev) {
        assert.equal("/foo/bar", ev.originalEvent.data.xhr.url);
        return done();
      });

      const server = sinon.fakeServer.create();
      server.respondWith("POST", "/foo/bar",
            [422, { "Content-Type": "text/html" },
             '<div id="foo" refresh="foo">Error occured</div>']);
      const remote = new TurboGraft.Remote({
        httpRequestType: "POST",
        httpUrl: "/foo/bar"
      }
      , this.initiating_target);
      remote.submit();

      return server.respond();
    });

    it('will trigger turbograft:remote:always on success with the XHR as the data', function(done) {
      $(this.initiating_target).one("turbograft:remote:always", function(ev) {
        assert.equal("/foo/bar", ev.originalEvent.data.xhr.url);
        return done();
      });

      const server = sinon.fakeServer.create();
      server.respondWith("POST", "/foo/bar",
            [200, { "Content-Type": "text/html" },
             '<div>Hey there</div>']);
      const remote = new TurboGraft.Remote({
        httpRequestType: "POST",
        httpUrl: "/foo/bar"
      }
      , this.initiating_target);
      remote.submit();

      return server.respond();
    });

    it('will trigger turbograft:remote:always on failure with the XHR as the data', function(done) {
      $(this.initiating_target).one("turbograft:remote:always", function(ev) {
        assert.equal("/foo/bar", ev.originalEvent.data.xhr.url);
        return done();
      });

      const server = sinon.fakeServer.create();
      server.respondWith("POST", "/foo/bar",
            [500, { "Content-Type": "text/html" },
             '<div id="foo" refresh="foo">Error occured</div>']);
      const remote = new TurboGraft.Remote({
        httpRequestType: "POST",
        httpUrl: "/foo/bar"
      }
      , this.initiating_target);
      remote.submit();

      return server.respond();
    });

    it('XHR=200: will trigger Page.refresh using XHR only', function() {
      const server = sinon.fakeServer.create();
      server.respondWith("POST", "/foo/bar",
            [200, { "Content-Type": "text/html" },
             '<div>Hey there</div>']);

      const remote = new TurboGraft.Remote({
        httpRequestType: "POST",
        httpUrl: "/foo/bar"
      }
      , this.initiating_target);
      remote.submit();

      server.respond();
      return assert(this.refreshStub.calledWith({
        response: sinon.match.has('responseText', '<div>Hey there</div>')})
      );
    });

    it('XHR=200: will trigger Page.refresh using XHR and refresh-on-success', function() {
      const server = sinon.fakeServer.create();
      server.respondWith("POST", "/foo/bar",
            [200, { "Content-Type": "text/html" },
             '<div>Hey there</div>']);

      const remote = new TurboGraft.Remote({
        httpRequestType: "POST",
        httpUrl: "/foo/bar",
        refreshOnSuccess: "a b c"
      }
      , this.initiating_target);
      remote.submit();

      server.respond();
      return assert(this.refreshStub.calledWith({
        response: sinon.match.has('responseText', '<div>Hey there</div>'),
        onlyKeys: ['a', 'b', 'c']}));
  });

    it('XHR=200: will trigger Page.refresh using XHR and refresh-on-success-except', function() {
      const server = sinon.fakeServer.create();
      server.respondWith("POST", "/foo/bar",
            [200, { "Content-Type": "text/html" },
             '<div>Hey there</div>']);

      const remote = new TurboGraft.Remote({
        httpRequestType: "POST",
        httpUrl: "/foo/bar",
        refreshOnSuccessExcept: "a b c"
      }
      , this.initiating_target);
      remote.submit();

      server.respond();
      return assert(this.refreshStub.calledWith({
        response: sinon.match.has('responseText', '<div>Hey there</div>'),
        exceptKeys: ['a', 'b', 'c']}));
  });

    it('XHR=200: will trigger Page.refresh with refresh-on-success when full-refresh is provided', function() {
      const server = sinon.fakeServer.create();
      server.respondWith("POST", "/foo/bar",
            [200, { "Content-Type": "text/html" },
             '<div>Hey there</div>']);
      const remote = new TurboGraft.Remote({
        httpRequestType: "POST",
        httpUrl: "/foo/bar",
        refreshOnSuccess: "a b c",
        fullRefresh: true
      }
      , this.initiating_target);
      remote.submit();

      server.respond();

      return assert(this.refreshStub.calledWith({
        onlyKeys: ['a', 'b', 'c']}));
  });

    it('XHR=200: will trigger Page.refresh with no arguments when full-refresh is present and refresh-on-success is not provided', function() {
      const server = sinon.fakeServer.create();
      server.respondWith("POST", "/foo/bar",
            [200, { "Content-Type": "text/html" },
             '<div>Hey there</div>']);
      const remote = new TurboGraft.Remote({
        httpRequestType: "POST",
        httpUrl: "/foo/bar",
        fullRefresh: true
      }
      , this.initiating_target);
      remote.submit();

      server.respond();

      assert.equal(1, this.refreshStub.callCount);
      return assert.equal(0, this.refreshStub.args[0].length);
    });

    it('XHR=200: will not trigger Page.refresh when tg-remote-norefresh is present on the initiator', function() {
      const server = sinon.fakeServer.create();
      server.respondWith("POST", "/foo/bar",
            [200, { "Content-Type": "text/html" },
             '<div>Hey there</div>']);

      this.initiating_target.setAttribute("tg-remote-norefresh", true);
      const remote = new TurboGraft.Remote({
        httpRequestType: "POST",
        httpUrl: "/foo/bar",
        fullRefresh: true
      }
      , this.initiating_target);
      remote.submit();

      server.respond();

      return assert.equal(0, this.refreshStub.callCount);
    });

    it('XHR=422: will trigger Page.refresh using XHR and refresh-on-error', function() {
      const server = sinon.fakeServer.create();
      server.respondWith("POST", "/foo/bar",
            [422, { "Content-Type": "text/html" },
             '<div id="foo" refresh="foo">Error occured</div>']);
      const remote = new TurboGraft.Remote({
        httpRequestType: "POST",
        httpUrl: "/foo/bar",
        refreshOnError: "a b c"
      }
      , this.initiating_target);
      remote.submit();

      server.respond();

      return assert(this.refreshStub.calledWith({
        response: sinon.match.has('responseText', '<div id="foo" refresh="foo">Error occured</div>'),
        onlyKeys: ['a', 'b', 'c']}));
  });

    it('XHR=422: will trigger Page.refresh using XHR and refresh-on-error-except', function() {
      const server = sinon.fakeServer.create();
      server.respondWith("POST", "/foo/bar",
            [422, { "Content-Type": "text/html" },
             '<div id="foo" refresh="foo">Error occured</div>']);
      const remote = new TurboGraft.Remote({
        httpRequestType: "POST",
        httpUrl: "/foo/bar",
        refreshOnErrorExcept: "a b c"
      }
      , this.initiating_target);
      remote.submit();

      server.respond();

      return assert(this.refreshStub.calledWith({
        response: sinon.match.has('responseText', '<div id="foo" refresh="foo">Error occured</div>'),
        exceptKeys: ['a', 'b', 'c']}));
  });

    it('XHR=422: will trigger Page.refresh with refresh-on-error when full-refresh is provided', function() {
      const server = sinon.fakeServer.create();
      server.respondWith("POST", "/foo/bar",
            [422, { "Content-Type": "text/html" },
             '<div id="foo" refresh="foo">Error occured</div>']);
      const remote = new TurboGraft.Remote({
        httpRequestType: "POST",
        httpUrl: "/foo/bar",
        refreshOnError: "a b c",
        fullRefresh: true
      }
      , this.initiating_target);
      remote.submit();

      server.respond();

      return assert(this.refreshStub.calledWith({
        onlyKeys: ['a', 'b', 'c']}));
  });

    it('XHR=422: will not trigger Page.refresh if no refresh-on-error is present', function() {
      const server = sinon.fakeServer.create();
      server.respondWith("POST", "/foo/bar",
            [422, { "Content-Type": "text/html" },
             '<div id="foo" refresh="foo">Error occured</div>']);
      const remote = new TurboGraft.Remote({
        httpRequestType: "POST",
        httpUrl: "/foo/bar"
      }
      , this.initiating_target);
      remote.submit();

      server.respond();

      return assert.equal(0, this.refreshStub.callCount);
    });

    it('XHR=422: will trigger Page.refresh with no arguments when full-refresh is present and refresh-on-error is not provided', function() {
      const server = sinon.fakeServer.create();
      server.respondWith("POST", "/foo/bar",
            [422, { "Content-Type": "text/html" },
             '<div id="foo" refresh="foo">Error occured</div>']);
      const remote = new TurboGraft.Remote({
        httpRequestType: "POST",
        httpUrl: "/foo/bar",
        fullRefresh: true
      }
      , this.initiating_target);
      remote.submit();

      server.respond();

      assert.equal(1, this.refreshStub.callCount);
      return assert.equal(0, this.refreshStub.args[0].length);
    });

    return it('XHR=422: will not trigger Page.refresh when tg-remote-norefresh is present on the initiator', function() {
      const server = sinon.fakeServer.create();
      server.respondWith("POST", "/foo/bar",
            [422, { "Content-Type": "text/html" },
             '<div id="foo" refresh="foo">Error occured</div>']);

      this.initiating_target.setAttribute("tg-remote-norefresh", true);
      const remote = new TurboGraft.Remote({
        httpRequestType: "POST",
        httpUrl: "/foo/bar",
        fullRefresh: true
      }
      , this.initiating_target);
      remote.submit();

      server.respond();

      return assert.equal(0, this.refreshStub.callCount);
    });
  });

  return describe('serialization', function() {
    it('will create FormData by calling formDataAppend for each valid input', function() {
      const form = $("<form><input type='file' name='foo'><input type='text' name='bar' value='fizzbuzz'></form>")[0];

      const appendSpy = sinon.spy(FormData.prototype, 'append');
      const formDataAppendSpy = sinon.spy(TurboGraft.Remote.prototype, 'formDataAppend');

      const remote = new TurboGraft.Remote({}, form);

      assert(appendSpy.calledOnce);
      return assert(formDataAppendSpy.calledTwice);
    });

    it('will create FormData object if there is a file in the form', function() {
      const form = $("<form><input type='file' name='foo'></form>")[0];

      const remote = new TurboGraft.Remote({}, form);
      return assert((remote.formData instanceof FormData));
    });

    it('will not create FormData object if the only input does not have a name', function() {
      const form = $("<form><input type='file'></form>")[0];

      const remote = new TurboGraft.Remote({}, form);
      return assert.isFalse((remote.formData instanceof FormData));
    });

    it('will create FormData object but skip any input which doesnt have a name', function() {
      const form = $("<form><input type='file' name='foo'><input type='file'></form>")[0];

      const remote = new TurboGraft.Remote({}, form);
      return assert((remote.formData instanceof FormData));
    });

    it('will add the _method to the form if supplied in the constructor', function() {
      const form = $("<form></form>")[0];

      const remote = new TurboGraft.Remote({httpRequestType: 'put'}, form);
      return assert.equal("_method=put", remote.formData);
    });

    it('will not override any Rails _method hidden input in the form, even if we try to using the constructor', function() {
      const form = $("<form method='POST'><input name='_method' value='PATCH'></form>")[0];
      // above: actual HTTP is POST, rails will interpret it as PATCH

      const remote = new TurboGraft.Remote({httpRequestType: 'DELETE'}, form); // DELETE should be ignored here
      return assert.equal("_method=PATCH", remote.formData);
    });

    it('will not set _method when using FormData', function() {
      let FormData;
      const form = $("<form><input type='file' name='foo'></form>")[0];

      const oldFormData = window.FormData;

      let constructed = false;
      window.FormData = (FormData = class FormData {
        constructor() {
          constructed = true;
          this.hash = {};
        }

        append(key, val) {
          return this.hash[key] = val;
        }
      });

      const remote = new TurboGraft.Remote({httpRequestType: 'DELETE'}, form);
      assert.equal(undefined, remote.formData.hash._method);
      assert.isTrue(constructed);

      return window.FormData = oldFormData;
    });

    it('will not add a _method if improperly supplied', function() {
      const form = $("<form method='POST'></form>")[0];

      const remote = new TurboGraft.Remote({httpRequestType: undefined}, form);
      return assert.equal("", remote.formData);
    });

    it('will create FormData object even if there is no file when useNativeEncoding specified', function() {
      const form = $("<form><input type='text' name='foo' value='bar'></form>")[0];

      const remote = new TurboGraft.Remote({useNativeEncoding: true}, form);
      return assert((remote.formData instanceof FormData));
    });

    it('will not create FormData object if there is no file in the form', function() {
      const form = $("<form><input type='text' name='foo' value='bar'></form>")[0];

      const remote = new TurboGraft.Remote({}, form);
      return assert.equal("foo=bar", remote.formData);
    });

    it('properly URL encodes multiple fields in the form', function() {
      const formDesc = `\
<form>
  <input type="text" name="foo" value="bar">
  <input type="text" name="faa" value="bat">
  <input type="text" name="fii" value="bam+">
  <textarea name="textarea">this is a test</textarea>
  <input type="text" name="disabled" disabled value="disabled">
  <input type="radio" name="radio1" value="A">
  <input type="radio" name="radio1" value="B" checked>
  <input type="checkbox" name="checkbox" value="C">
  <input type="checkbox" name="checkbox" value="D" checked>
  <input type="checkbox" name="disabled2" value="checked" checked disabled>
  <select name="select1">
    <option value="a">foo</option>
    <option value="b">foo</option>
    <option value="c" selected>foo</option>
  </select>
  <input type="text" name="foobar" value="foobat">
</form>\
`;
      const form = $(formDesc)[0];

      const remote = new TurboGraft.Remote({}, form);
      return assert.equal("foo=bar&faa=bat&fii=bam%2B&textarea=this%20is%20a%20test&radio1=B&checkbox=D&select1=c&foobar=foobat", remote.formData);
    });

    it('will set content type on XHR properly when form is URL encoded', function() {
      const form = $("<form><input type='text' name='foo' value='bar'></form>")[0];

      const remote = new TurboGraft.Remote({}, form);
      return assert.equal("application/x-www-form-urlencoded; charset=UTF-8", remote.xhr.requestHeaders["Content-Type"]);
  });

    return it('will ignore inputs with the tg-remote-noserialize attribute on them or on an ancestor', function() {
      const formDesc = `\
<form>
  <input type="text" name="foo" value="bar" tg-remote-noserialize>
  <input type="text" name="faa" value="bat">
  <input type="text" name="fii" value="bam+">
  <textarea name="textarea">this is a test</textarea>
  <input type="text" name="disabled" disabled value="disabled">
  <input type="radio" name="radio1" value="A">
  <input type="radio" name="radio1" value="B" checked>
  <input type="checkbox" name="checkbox" value="C">
  <input type="checkbox" name="checkbox" value="D" checked>
  <input type="checkbox" name="disabled2" value="checked" checked disabled>
  <select name="select1">
    <option value="a">foo</option>
    <option value="b">foo</option>
    <option value="c" selected>foo</option>
  </select>
  <input type="text" name="foobar" value="foobat">
  <div tg-remote-noserialize>
    <span>
      <input type="text" name="nope" value="nope">
      <textarea name="textarea2" tg-remote-noserialize>this is also a test</textarea>
      <input type="radio" name="radio2" value="Y">
      <input type="radio" name="radio2" value="X" checked>
      <select name="select2">
        <option value="x">foo</option>
        <option value="y">foo</option>
        <option value="z" selected>foo</option>
      </select>
    </span>
  </div>
</form>\
`;

      const form = $(formDesc)[0];

      const remote = new TurboGraft.Remote({}, form);
      return assert.equal("faa=bat&fii=bam%2B&textarea=this%20is%20a%20test&radio1=B&checkbox=D&select1=c&foobar=foobat", remote.formData);
    });
  });
});
