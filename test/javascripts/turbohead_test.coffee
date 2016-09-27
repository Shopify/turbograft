#= require ./fake_document

describe 'TurboHead', ->
  activeDocument = null
  promiseQueue = null
  requests = []

  assertScriptCount = (size, message) ->
    promiseQueue = promiseQueue.then ->
      assert.lengthOf(activeDocument.createdScripts, size, message)

  nextUnloadedScript = ->
    unloaded = activeDocument.createdScripts.filter (script) ->
      !script.isLoaded && !script.isError
    throw new Error('No unloaded scripts') if !unloaded[0]

    unloaded[0]

  failScriptDownload = ->
    promiseQueue = promiseQueue.then ->
      new Promise (resolve) ->
        unloaded = nextUnloadedScript()
        unloaded.fireError().then ->
          setTimeout -> resolve(unloaded)

  finishScriptDownload = ->
    promiseQueue = promiseQueue.then ->
      new Promise (resolve) ->
        unloaded = nextUnloadedScript()
        unloaded.fireLoaded().then ->
          setTimeout -> resolve(unloaded)

  newRequest = (requestScripts) ->
    promiseQueue = promiseQueue.then ->
      new Promise (resolve) ->
        head = new TurboGraft.TurboHead(
          activeDocument,
          fakeDocument(requestScripts)
        )

        request = head.waitForAssets()
        request.isInProgress = true
        request.isFulfilled = false
        request.isRejected = false
        request.isError = false
        request
          .then (result) ->
            request.isInProgress = false
            request.isCanceled = Boolean(result.isCanceled)
            request.isFulfilled = !request.isCanceled
          .catch -> request.isRejected = true
        requests.push(request)

        setTimeout(resolve, 50) # Wait for beginning of first script download.

  beforeEach ->
    activeDocument = fakeDocument([]) # Start with no scripts.
    promiseQueue = Promise.resolve()
    requests = []

  afterEach ->
    TurboGraft.TurboHead._testAPI.reset()

  describe 'script download queue', ->
    it 'downloads scripts in sequence', ->
      newRequest(['a.js', 'b.js', 'c.js'])
      assertScriptCount(1, 'first script download should be in progress')
      finishScriptDownload()
        .then (script) -> assert.equal(script.src, 'a.js')

      assertScriptCount(2, 'first download complete should trigger second')
      finishScriptDownload()
        .then (script) -> assert.equal(script.src, 'b.js')

      assertScriptCount(3, 'second download complete should trigger third')
      finishScriptDownload()
        .then (script) ->
          assert.equal(script.src, 'c.js')
          assert.isTrue(
            requests[0].isFulfilled,
            'all downloads complete should resolve request'
          )

    describe 'superceded requests', ->
      it 'cancels stale requests', ->
        newRequest(['d.js'])
        newRequest([]).then ->
          assert.isTrue(requests[0].isCanceled)

      it 'waits for previously queued scripts before starting new request', ->
        newRequest(['a.js', 'b.js'])
        newRequest([])
        finishScriptDownload()
        finishScriptDownload()
        assertScriptCount(2, 'duplicate script elements should not be created')
          .then ->
            assert.isTrue(requests[0].isCanceled)
            assert.isTrue(requests[1].isFulfilled)

      it 'does not add duplicate script tags for new requests', ->
        newRequest(['a.js', 'b.js'])
        newRequest(['a.js', 'b.js'])
        assertScriptCount(1, 'first script should be downloading').then ->
          assert.isTrue(requests[1].isInProgress)
        finishScriptDownload()
        finishScriptDownload()
          .then ->
            assertScriptCount(2, 'duplicate script elements were created')
            assert.isTrue(requests[1].isFulfilled)

      it 'enqueues new scripts for new requests', ->
        newRequest(['a.js', 'b.js'])
        newRequest(['b.js', 'c.js', 'd.js'])
        finishScriptDownload()
        finishScriptDownload().then ->
          assert.isTrue(requests[1].isInProgress)
        finishScriptDownload().then ->
          assert.isTrue(requests[1].isInProgress)
        finishScriptDownload().then (script) ->
          assertScriptCount(4, 'second request\'s assets should be downloaded')
          assert.equal(
            script.src, 'd.js',
            'last queued script should be last downloaded'
          )
          assert.isTrue(requests[1].isFulfilled)

      it 'does not reload completed scripts for new requests', ->
        newRequest(['a.js', 'b.js'])
        finishScriptDownload()
        finishScriptDownload().then ->
          assertScriptCount(2)
          assert.isTrue(requests[0].isFulfilled)
        newRequest(['a.js', 'b.js']).then ->
          assertScriptCount(2)
          assert.isTrue(requests[1].isFulfilled)

  describe 'script errors', ->
    it 'sends events for script errors', ->
      promise = new Promise (resolve) ->
        $(document).one('page:script-error', (evt) ->
          assert.equal(evt.originalEvent.data.url, 'a.js')
          resolve()
        )

      newRequest(['a.js'])
      failScriptDownload()
      promise

    it 'fulfills requests with script errors', ->
      newRequest(['a.js', 'b.js', 'c.js'])
      finishScriptDownload()
      failScriptDownload()
      finishScriptDownload().then ->
        assert.isTrue(requests[0].isFulfilled)
