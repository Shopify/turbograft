/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
describe('Turbolinks', function() {
  const baseHTML = '<html><head></head><body></body></html>';
  let iframe = null;
  let testDocument = null;
  let sandbox = null;
  let pushStateStub = null;
  let replaceStateStub = null;
  let resetScrollStub = null;

  const ROUTE_TEMPLATE_INDEX = 2;

  const TURBO_EVENTS = [
    'page:change',
    'page:update',
    'page:load',
    'page:before-change',
    'page:before-partial-replace',
    'page:after-change',
    'page:after-node-removed',
    'page:fetch',
    'page:receive',
    'page:after-script-inserted',
    'page:after-link-inserted',
    'page:after-link-removed',
    'page:script-error'
  ];

  const hasScript = filename => testDocument.querySelectorAll(`script[src=\"${ASSET_FIXTURES[filename]}\"]`).length > 0;

  const assetFixturePath = function(filename) {
    const path = ASSET_FIXTURES[filename];
    if (path == null) { throw new Error(`NO ASSET PATH FOR ${filename}`); }
    return path;
  };

  const assertScripts = function(expected) {
    let actual, expectedAssets;
    return assert.deepEqual(
      (actual = scriptsInHead()),
      (expectedAssets = expected.map(assetFixturePath)),
      `expected scripts in head: ${actual} to match expected: ${expectedAssets}`
    );
  };

  const assertLinks = function(expected) {
    let actual, expectedAssets;
    return assert.deepEqual(
      (actual = linksInHead()),
      (expectedAssets = expected.map(assetFixturePath)),
      `expected links in head: ${actual} to match expected: ${expectedAssets}`
    );
  };

  var scriptsInHead = () => [].slice.call(testDocument.head.children)
    .filter(node => node.nodeName === 'SCRIPT')
    .map(node => node.getAttribute('src'));

  var linksInHead = () => [].slice.call(testDocument.head.children)
    .filter(node => node.nodeName === 'LINK')
    .map(node => node.getAttribute('href'));

  const resetPage = function() {
    testDocument.head.innerHTML = "";
    return testDocument.body.innerHTML = `\
<div id="turbo-area" refresh="turbo-area"></div>\
`;
  };

  const setupIframe = function() {
    iframe = document.createElement('iframe');
    document.body.appendChild(iframe);
    iframe.contentDocument.write(baseHTML);
    return iframe.contentDocument;
  };

  const startFromFixture = function(route) {
    const fixtureHTML = ROUTES[route][2];
    return testDocument.documentElement.innerHTML = fixtureHTML;
  };

  const urlFor = slug => window.location.origin + slug;

  const visit = function({options, url}, callback) {
    $(testDocument).one('page:load', event => setTimeout((function() { if (callback) { return callback(event); } }), 0));
    return Turbolinks.visit('/' + url, options);
  };

  beforeEach(function() {
    testDocument = setupIframe();
    Turbolinks.document(testDocument);
    sandbox = sinon.sandbox.create();
    pushStateStub = sandbox.stub(Turbolinks, 'pushState');
    replaceStateStub = sandbox.stub(Turbolinks, 'replaceState');
    resetScrollStub = sandbox.stub(Turbolinks, 'resetScrollPosition');
    sandbox.stub(Turbolinks, 'fullPageNavigate', () => $(testDocument).trigger('page:load'));
    sandbox.useFakeServer();

    Object.keys(ROUTES).forEach(url => sandbox.server.respondWith('/' + url, ROUTES[url]));
    sandbox.server.autoRespond = true;

    $("script").attr("data-turbolinks-eval", false);
    $("#mocha").attr("refresh-never", true);

    TurboGraft.TurboHead._testAPI.reset();
    return resetPage();
  });

  afterEach(function() {
    sandbox.restore();
    $(testDocument).off(TURBO_EVENTS.join(' '));
    return $("#turbo-area").remove();
  });

  it('is defined', () => assert(Turbolinks));

  describe('#visit', function() {
    it('subsequent visits abort previous XHRs', function(done) {
      const pageReceive = stub();
      $(testDocument).on('page:receive', pageReceive);
      visit({url: 'noScriptsOrLinkInHead'}, () => true);
      return visit({url: 'noScriptsOrLinkInHead'}, function() {
        assert(pageReceive.calledOnce, 'page:receive should only be emitted once!');
        return done();
      });
    });

    it('returns if pageChangePrevented', function(done) {
      $(testDocument).one('page:before-change', function(event) {
        event.preventDefault();
        assert.equal('/noScriptsOrLinkInHead', event.originalEvent.data);
        assert.equal(0, sandbox.server.requests.length);
        return done();
      });

      return visit({url: 'noScriptsOrLinkInHead', options: { partialReplace: true, onlyKeys: ['turbo-area'] }});
    });

    it('supports passing request headers', done => visit({url: 'noScriptsOrLinkInHead', options: { headers: {'foo': 'bar', 'fizz': 'buzz'} }}, function() {
      assert.equal('bar', sandbox.server.requests[0].requestHeaders['foo']);
      assert.equal('buzz', sandbox.server.requests[0].requestHeaders['fizz']);
      return done();
    }));

    it('updates the browser history stack', done => visit({url: 'noScriptsOrLinkInHead'}, function() {
      assert(pushStateStub.called, 'pushState was not called!');
      return done();
    }));

    it('calls a user-supplied callback', function(done) {
      const yourCallback = stub();
      return visit({url: 'noScriptsOrLinkInHead', options: {callback: yourCallback}}, function() {
        assert(yourCallback.calledOnce, 'Callback was not called.');
        return done();
      });
    });

    return it('resets the scroll position', done => visit({url: 'noScriptsOrLinkInHead'}, function() {
      assert.calledOnce(resetScrollStub);
      return done();
    }));
  });

  describe('loadPage', function() {
    const PAGE_CONTENT = 'Oh hi, mark!';

    it('is synchronous when a partial replace', function() {
      startFromFixture('noScriptsOrLinkInHead');
      const xhr = new sinon.FakeXMLHttpRequest();
      xhr.open('POST', '/my/endpoint', true);
      xhr.respond(200, {'Content-Type':'text/html'}, PAGE_CONTENT);

      Turbolinks.loadPage(null, xhr, {partialReplace: true});

      return assert.include(testDocument.body.textContent, PAGE_CONTENT);
    });

    return it('is asynchronous when not a partial replace', function(done) {
      startFromFixture('noScriptsOrLinkInHead');
      const xhr = new sinon.FakeXMLHttpRequest();
      xhr.open('POST', '/my/endpoint', true);
      xhr.respond(200, {'Content-Type':'text/html'}, PAGE_CONTENT);

      Turbolinks.loadPage(null, xhr).then(function() {
        assert.include(testDocument.body.textContent, PAGE_CONTENT);
        return done();
      });
      return assert.notInclude(testDocument.body.textContent, PAGE_CONTENT);
    });
  });

  describe('head asset tracking', function() {
    it('refreshes page when moving from a page with tracked assets to a page with none', function(done) {
      startFromFixture('singleScriptInHead');
      return visit({url: 'noScriptsOrLinkInHead'}, function() {
        assert(Turbolinks.fullPageNavigate.called, 'Should perform a full page refresh.');
        return done();
      });
    });

    it('refreshes page when a data-turbolinks-track value matches but src changes', function(done) {
      startFromFixture('singleScriptInHead');
      return visit({url: 'singleScriptInHeadWithDifferentSourceButSameName'}, function() {
        assert(Turbolinks.fullPageNavigate.called, 'Should perform a full page refresh.');
        return done();
      });
    });

    it('does not refresh page when new data-turbolinks-track values encountered', function(done) {
      startFromFixture('singleScriptInHead');
      return visit({url: 'twoScriptsInHead'}, function() {
        assert(Turbolinks.fullPageNavigate.notCalled, 'Should not perform a full page refresh.');
        return done();
      });
    });

    it('does not update the browser history stack when a conflict is detected', function(done) {
      startFromFixture('singleScriptInHead');
      return visit({url: 'singleScriptInHeadWithDifferentSourceButSameName'}, function() {
        assert(pushStateStub.notCalled, 'pushState was called');
        return done();
      });
    });

    describe('using data-turbolinks-track="true"', function() {
      it('refreshes page when a new tracked node is present', done => visit({url: 'singleScriptInHeadTrackTrue'}, function() {
        assert(Turbolinks.fullPageNavigate.called, 'Should perform a full page refresh.');
        return done();
      }));

      it('refreshes page when an extant tracked node is missing', function(done) {
        startFromFixture('twoScriptsInHeadTrackTrue');
        return visit({url: 'singleScriptInHeadTrackTrue'}, function() {
          assert(Turbolinks.fullPageNavigate.called, 'Should perform a full page refresh.');
          return done();
        });
      });

      it('refreshes page when upstream and active tracked scripts lengths are equal but one\'s source changes', function(done) {
        startFromFixture('twoScriptsInHeadTrackTrue');
        return visit({url: 'twoScriptsInHeadTrackTrueOneChanged'}, function() {
          assert(Turbolinks.fullPageNavigate.called, 'Should perform a full page refresh.');
          return done();
        });
      });

      it('refreshes page when upstream and active tracked links lengths are equal but one\'s source changes', function(done) {
        startFromFixture('twoLinksInHeadTrackTrue');
        return visit({url: 'twoLinksInHeadTrackTrueOneChanged'}, function() {
          assert(Turbolinks.fullPageNavigate.called, 'Should perform a full page refresh.');
          return done();
        });
      });

      it('does not update the browser history stack in cases where it will force a refresh', function(done) {
        startFromFixture('singleScriptInHead');
        return visit({url: 'singleScriptInHeadWithDifferentSourceButSameName'}, function() {
          assert(pushStateStub.notCalled, 'pushState was called');
          return done();
        });
      });

      return it('does not refresh page when tracked nodes have matching sources', function(done) {
        startFromFixture('singleScriptInHeadTrackTrue');
        return visit({url: 'singleScriptInHeadTrackTrue'}, function() {
          assert(Turbolinks.fullPageNavigate.notCalled, 'Should not perform a full page refresh.');
          return done();
        });
      });
    });

    describe('link tags', function() {
      it('dispatches page:after-link-inserted event when inserting a link on navigation', function(done) {
        const linkTagInserted = sinon.spy();
        $(testDocument).on('page:after-link-inserted', linkTagInserted);

        return visit({url: 'singleLinkInHead'}, function() {
          assertLinks(['foo.css']);
          assert.equal(linkTagInserted.callCount, 1);
          return done();
        });
      });

      it('inserts link with a new href into empty head on navigation', done => visit({url: 'singleLinkInHead'}, function() {
        assertLinks(['foo.css']);
        return done();
      }));

      it('inserts link with a new href into existing head on navigation', function(done) {
        startFromFixture('singleLinkInHead');
        return visit({url: 'twoLinksInHead'}, function() {
          assertLinks(['foo.css', 'bar.css']);
          return done();
        });
      });

      return it('does not reinsert link with existing href into identical head on navigation', function(done) {
        startFromFixture('singleLinkInHead');
        return visit({url: 'singleLinkInHead'}, function() {
          assertLinks(['foo.css']);
          return done();
        });
      });
    });

    return describe('script tags', function() {
      it('dispatches page:after-script-inserted event when inserting a script on navigation', function(done) {
        const scriptTagInserted = sinon.spy();
        $(testDocument).on('page:after-script-inserted', scriptTagInserted);
        return visit({url: 'singleScriptInHead'}, function() {
          assert.equal(scriptTagInserted.callCount, 1);
          return done();
        });
      });

      it('inserts script with a new src into empty head on navigation', done => visit({url: 'singleScriptInHead'}, function() {
        assertScripts(['foo.js']);
        return done();
      }));

      it('inserts script with a new src into existing head on navigation', function(done) {
        startFromFixture('singleScriptInHead');
        return visit({url: 'twoScriptsInHead'}, function() {
          assertScripts(['foo.js', 'bar.js']);
          return done();
        });
      });

      it('does not insert duplicate script tag on navigation into identical upstream head', function(done) {
        startFromFixture('singleScriptInHead');
        return visit({url: 'singleScriptInHead'}, function() {
          assertScripts(['foo.js']);
          return done();
        });
      });

      it('does not insert duplicate script tag on navigation into superset upstream head', function(done) {
        startFromFixture('singleScriptInHead');
        return visit({url: 'twoScriptsInHead'}, function() {
          assertScripts(['foo.js', 'bar.js']);
          return done();
        });
      });

      it('does not remove script when navigating to a page with an empty head', function(done) {
        startFromFixture('singleScriptInHead');
        return visit({url: 'noScriptsOrLinkInHead'}, function() {
          assertScripts(['foo.js']);
          return done();
        });
      });

      it('does not remove script nodes when navigating to a page with less script tags', function(done) {
        startFromFixture('twoScriptsInHead');
        return visit({url: 'singleScriptInHead'}, function() {
          assertScripts(['foo.js', 'bar.js']);
          return done();
        });
      });

      return describe('executes scripts in the order they are present in the dom of the upstream document', function() {
        beforeEach(() => window.actualExecutionOrder = []);

        it('works in order ABC', function(done) {
          const expectedScriptOrder = ['a', 'b', 'c'];
          return visit({url: 'threeScriptsInHeadABC'}, function() {
            assert.deepEqual(actualExecutionOrder, expectedScriptOrder);
            return done();
          });
        });

        it('works in order ACB', done => visit({url: 'threeScriptsInHeadACB'}, function() {
          const expectedScriptOrder = ['a', 'c', 'b'];
          assert.deepEqual(actualExecutionOrder, expectedScriptOrder);
          return done();
        }));

        it('works in order BAC', done => visit({url: 'threeScriptsInHeadBAC'}, function() {
          const expectedScriptOrder = ['b', 'a', 'c'];
          assert.deepEqual(actualExecutionOrder, expectedScriptOrder);
          return done();
        }));

        it('works in order BCA', done => visit({url: 'threeScriptsInHeadBCA'}, function() {
          const expectedScriptOrder = ['b', 'c', 'a'];
          assert.deepEqual(actualExecutionOrder, expectedScriptOrder);
          return done();
        }));

        it('works in order CAB', done => visit({url: 'threeScriptsInHeadCAB'}, function() {
          const expectedScriptOrder = ['c', 'a', 'b'];
          assert.deepEqual(actualExecutionOrder, expectedScriptOrder);
          return done();
        }));

        it('works in order CBA', done => visit({url: 'threeScriptsInHeadCBA'}, function() {
          const expectedScriptOrder = ['c', 'b', 'a'];
          assert.deepEqual(actualExecutionOrder, expectedScriptOrder);
          return done();
        }));

        return it('executes new scripts in the relative order they are present in the dom of the upstream document', done => visit({url: 'secondLibraryOnly'}, function() {
          assert.equal(actualExecutionOrder[0], 'b');
          return visit({url: 'threeScriptsInHeadABC'}, function() {
            assert.equal(actualExecutionOrder[1], 'a');
            assert.equal(actualExecutionOrder[2], 'c');
            return done();
          });
        }));
      });
    });
  });

  describe('with partial page replacement', function() {
    beforeEach(() => window.globalStub = stub());
    it('does not reset scroll position during partial replace', done => visit({url: 'singleScriptInHead', options: {
        partialReplace: true,
        onlyKeys: ['turbo-area']
      }
  }, function() {
      assert.notCalled(resetScrollStub);
      return done();
    }));

    it('head assets are not inserted during partial replace', done => visit({url: 'singleScriptInHead', options: {
          partialReplace: true,
          onlyKeys: ['turbo-area']
        }
  }, function() {
      assertScripts([]);
      return done();
    }));

    it('head assets are not removed during partial replace', function(done) {
      startFromFixture('singleLinkInHead');
      return visit({url: 'twoLinksInHead', options: {partialReplace: true, onlyKeys: ['turbo-area']}}, function() {
        assertLinks(['foo.css']);
        return done();
      });
    });

    it('script tags are evaluated when they are the subject of a partial replace', done => visit({url: 'inlineScriptInBody', options: {partialReplace: true, onlyKeys: ['turbo-area']}}, function() {
      assert(globalStub.calledOnce, 'Script tag was not evaluated :(');
      return done();
    }));

    it('calls a user-supplied callback', function(done) {
      const yourCallback = stub();
      return visit({url: 'noScriptsOrLinkInHead', options: {partialReplace: true, onlyKeys: ['turbo-area'], callback: yourCallback}}, function() {
        assert(yourCallback.calledOnce, 'Callback was not called.');
        return done();
      });
    });

    it('script tags are not evaluated if they have [data-turbolinks-eval="false"]', done => visit({url: 'inlineScriptInBodyTurbolinksEvalFalse', options: {partialReplace: true, onlyKeys: ['turbo-area']}}, function() {
      assert.equal(0, globalStub.callCount);
      return done();
    }));

    it('pushes state onto history stack', done => visit({url: 'noScriptsOrLinkInHead',  options: {partialReplace: true, onlyKeys: ['turbo-area']}}, function() {
      assert(Turbolinks.pushState.called, 'pushState not called');
      assert(Turbolinks.pushState.calledWith({turbolinks: true, url: urlFor('/noScriptsOrLinkInHead')}, '', urlFor('/noScriptsOrLinkInHead')), 'Turbolinks.pushState not called with proper args');
      assert.equal(0, replaceStateStub.callCount);
      assert.equal(1, sandbox.server.requests.length);
      return done();
    }));

    it('doesn\'t add a new history entry if updatePushState is false', done => visit({url: 'noScriptsOrLinkInHead', options: {partialReplace: true, onlyKeys: ['turbo-area'], updatePushState: false}}, function() {
      assert(pushStateStub.notCalled, 'pushState should not be called');
      assert(replaceStateStub.notCalled, 'replaceState should not be called');
      return done();
    }));

    it('uses just the part of the response body we supply', done => visit({url: 'noScriptsOrLinkInHead',  options: {partialReplace: true, onlyKeys: ['turbo-area']}}, function() {
      assert.equal("Hi there!", testDocument.title);
      assert.notInclude(testDocument.body.textContent, 'YOLO');
      assert.include(testDocument.body.textContent, 'Hi bob');
      return done();
    }));

    it('triggers the page:load event with a list of nodes that are new (freshly replaced)', done => visit({url: 'noScriptsOrLinkInHead', options: {partialReplace: true, onlyKeys: ['turbo-area']}}, function(event) {
      const ev = event.originalEvent;
      assert.instanceOf(ev.data, Array);
      assert.lengthOf(ev.data, 1);
      const node = ev.data[0];

      assert.equal('turbo-area', node.id);
      assert.equal('turbo-area', node.getAttribute('refresh'));
      return done();
    }));

    it('does not trigger the page:before-partial-replace event more than once', function(done) {
      const handler = stub();
      $(testDocument).on('page:before-partial-replace', handler);

      return visit({url: 'noScriptsOrLinkInHead', options: {partialReplace: true, onlyKeys: ['turbo-area']}}, function() {
        assert(handler.calledOnce);
        return done();
      });
    });

    return it('refreshes only outermost nodes of dom subtrees with refresh keys', done => visit({url: 'responseWithRefreshAlways'}, function() {
      $(testDocument).on('page:before-partial-replace', function(ev) {
        const nodes = ev.originalEvent.data;
        assert.equal(2, nodes.length);
        assert.equal('div2', nodes[0].id);
        return assert.equal('div1', nodes[1].id);
      });

      return visit({url: 'responseWithRefreshAlways', options: {onlyKeys: ['div1']}}, function(ev) {
        const nodes = ev.originalEvent.data;
        assert.equal(1, nodes.length);
        assert.equal('div1', nodes[0].id);
        return done();
      });
    }));
  });

  return describe('asset loading finished', function() {
    const SUCCESS_HTML_CONTENT = 'Hi there';
    let xhr = null;
    let resolver = null;

    beforeEach(function() {
      const promise = new Promise(resolve => resolver = resolve);
      sandbox.stub(TurboGraft.TurboHead.prototype, 'hasAssetConflicts').returns(false);
      sandbox.stub(TurboGraft.TurboHead.prototype, 'waitForAssets').returns(promise);

      xhr = new sinon.FakeXMLHttpRequest();
      xhr.open('POST', '/my/endpoint', true);
      return xhr.respond(200, {'Content-Type':'text/html'}, SUCCESS_HTML_CONTENT);
    });

    it('does not update document if the request was canceled', function() {
      let loadPromise;
      resolver({isCanceled: true});
      return loadPromise = Turbolinks.loadPage(new ComponentUrl('/foo'), xhr)
        .then(() => assert.notInclude(testDocument.body.innerHTML, SUCCESS_HTML_CONTENT));
    });

    return it('updates the document if the request was not canceled', function() {
      let loadPromise;
      resolver();
      return loadPromise = Turbolinks.loadPage(new ComponentUrl('/foo'), xhr)
        .then(() => assert.include(testDocument.body.innerHTML, SUCCESS_HTML_CONTENT));
    });
  });
});
