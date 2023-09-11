/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
//= require ./fake_document

describe('TurboHead', function() {
  let activeDocument = null;
  let promiseQueue = null;
  let requests = [];

  const assertScriptCount = (size, message) => promiseQueue = promiseQueue.then(() => assert.lengthOf(activeDocument.createdScripts, size, message));

  const finishScriptDownload = () => promiseQueue = promiseQueue.then(() => new Promise(function(resolve) {
    const unloaded = activeDocument.createdScripts.filter(script => !script.isLoaded);

    return unloaded[0].fireLoaded().then(() => setTimeout(() => resolve(unloaded[0])));
  }));

  const newRequest = requestScripts => // Wait for beginning of first script download.
  promiseQueue = promiseQueue.then(() => new Promise(function(resolve) {
    const head = new TurboGraft.TurboHead(
      activeDocument,
      fakeDocument(requestScripts)
    );

    const request = head.waitForAssets();
    request.isInProgress = true;
    request.isFulfilled = false;
    request.isRejected = false;
    request
      .then(function(result) {
        request.isInProgress = false;
        request.isCanceled = Boolean(result.isCanceled);
        return request.isFulfilled = !request.isCanceled;}).catch(() => request.isRejected = true);
    requests.push(request);

    return setTimeout(resolve, 50);
  }));

  beforeEach(function() {
    activeDocument = fakeDocument([]); // Start with no scripts.
    promiseQueue = Promise.resolve();
    return requests = [];});

  afterEach(() => TurboGraft.TurboHead._testAPI.reset());

  return describe('script download queue', function() {
    it('downloads scripts in sequence', function() {
      newRequest(['a.js', 'b.js', 'c.js']);
      assertScriptCount(1, 'first script download should be in progress');
      finishScriptDownload()
        .then(script => assert.equal(script.src, 'a.js'));

      assertScriptCount(2, 'first download complete should trigger second');
      finishScriptDownload()
        .then(script => assert.equal(script.src, 'b.js'));

      assertScriptCount(3, 'second download complete should trigger third');
      return finishScriptDownload()
        .then(function(script) {
          assert.equal(script.src, 'c.js');
          return assert.isTrue(
            requests[0].isFulfilled,
            'all downloads complete should resolve request'
          );
      });
    });

    return describe('superceded requests', function() {
      it('cancels stale requests', function() {
        newRequest(['d.js']);
        return newRequest([]).then(() => assert.isTrue(requests[0].isCanceled));
      });

      it('waits for previously queued scripts before starting new request', function() {
        newRequest(['a.js', 'b.js']);
        newRequest([]);
        finishScriptDownload();
        finishScriptDownload();
        return assertScriptCount(2, 'duplicate script elements should not be created')
          .then(function() {
            assert.isTrue(requests[0].isCanceled);
            return assert.isTrue(requests[1].isFulfilled);
        });
      });

      it('does not add duplicate script tags for new requests', function() {
        newRequest(['a.js', 'b.js']);
        newRequest(['a.js', 'b.js']);
        assertScriptCount(1, 'first script should be downloading').then(() => assert.isTrue(requests[1].isInProgress));
        finishScriptDownload();
        return finishScriptDownload()
          .then(function() {
            assertScriptCount(2, 'duplicate script elements were created');
            return assert.isTrue(requests[1].isFulfilled);
        });
      });

      it('enqueues new scripts for new requests', function() {
        newRequest(['a.js', 'b.js']);
        newRequest(['b.js', 'c.js', 'd.js']);
        finishScriptDownload();
        finishScriptDownload().then(() => assert.isTrue(requests[1].isInProgress));
        finishScriptDownload().then(() => assert.isTrue(requests[1].isInProgress));
        return finishScriptDownload().then(function(script) {
          assertScriptCount(4, 'second request\'s assets should be downloaded');
          assert.equal(
            script.src, 'd.js',
            'last queued script should be last downloaded'
          );
          return assert.isTrue(requests[1].isFulfilled);
        });
      });

      return it('does not reload completed scripts for new requests', function() {
        newRequest(['a.js', 'b.js']);
        finishScriptDownload();
        finishScriptDownload().then(function() {
          assertScriptCount(2);
          return assert.isTrue(requests[0].isFulfilled);
        });
        return newRequest(['a.js', 'b.js']).then(function() {
          assertScriptCount(2);
          return assert.isTrue(requests[1].isFulfilled);
        });
      });
    });
  });
});
