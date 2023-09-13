/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS201: Simplify complex destructure assignments
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
describe('TurboGraft.Response', function() {
  let sandbox = null;
  let iframe = null;
  const baseHTML = '<html><head></head><body></body></html>';

  const responseForFixture = function(...args) {
    const obj = args[0],
          {
            fixture
          } = obj,
          val = obj.intendedURL,
          intendedURL = val != null ? val : null,
          callback = args[1];
    const xhr = new XMLHttpRequest;
    xhr.open("GET", `/${fixture}`, true);
    xhr.send();
    xhr.onload = () => callback(new TurboGraft.Response(xhr, intendedURL));
    return xhr.onerror = () => callback(new TurboGraft.Response(xhr, intendedURL));
  };

  const setupIframe = function() {
    iframe = document.createElement('iframe');
    document.body.appendChild(iframe);
    iframe.contentDocument.write(baseHTML);
    return iframe.contentDocument;
  };

  beforeEach(function() {
    let testDocument;
    if (!iframe) { testDocument = setupIframe(); }
    Turbolinks.document(testDocument);
    sandbox = sinon.sandbox.create();
    sandbox.useFakeServer();
    Object.keys(ROUTES).forEach(url => sandbox.server.respondWith('/' + url, ROUTES[url]));
    return sandbox.server.autoRespond = true;
  });

  afterEach(() => sandbox.restore());

  it('is defined', () => assert(TurboGraft.Response));

  describe('valid', function() {
    it('returns false when a server error is encountered', done => responseForFixture({ fixture: 'serverError' }, function(response) {
      assert(!response.valid(), 'response should not be valid when an error is received');
      return done();
    }));

    it('returns true when a 422 error is encountered', done => responseForFixture({ fixture: 'validationError' }, function(response) {
      assert(response.valid(), 'response should be valid when a 422 error is received');
      return done();
    }));

    it('returns true when a success status is encountered', done => responseForFixture({ fixture: 'noScriptsOrLinkInHead' }, function(response) {
      assert(response.valid(), 'response should be valid when a 200 is received');
      return done();
    }));

    return it('throws an error when Content-Type is empty', done => responseForFixture({ fixture: 'noContentType' }, function(response) {
      assert.throws(response.valid);
      return done();
    }));
  });

  return describe('document', function() {
    it('returns TurboGraft.Document.create when valid', function(done) {
      const stub = sandbox.stub(TurboGraft.Document, 'create', () => 'document');
      return responseForFixture({ fixture: 'noScriptsOrLinkInHead' }, function(response) {
        assert.equal(response.document(), 'document');
        return done();
      });
    });

    return it('returns undefined when invalid', done => responseForFixture({ fixture: 'serverError' }, function(response) {
      assert.equal(response.document(), undefined);
      return done();
    }));
  });
});
