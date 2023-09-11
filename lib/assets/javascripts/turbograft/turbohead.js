/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const TRACKED_ASSET_SELECTOR = '[data-turbolinks-track]';
const TRACKED_ATTRIBUTE_NAME = 'turbolinksTrack';
const ANONYMOUS_TRACK_VALUE = 'true';

let scriptPromises = {};
let resolvePreviousRequest = null;

const waitForCompleteDownloads = function() {
  const loadingPromises = Object.keys(scriptPromises).map(url => scriptPromises[url]);
  return Promise.all(loadingPromises);
};

const Cls = (TurboGraft.TurboHead = class TurboHead {
  static initClass() {
  
    this._testAPI = {
      reset() {
        scriptPromises = {};
        return resolvePreviousRequest = null;
      }
    };
  }
  constructor(activeDocument, upstreamDocument) {
    this._insertNewAssets = this._insertNewAssets.bind(this);
    this.activeDocument = activeDocument;
    this.upstreamDocument = upstreamDocument;
    this.activeAssets = extractTrackedAssets(this.activeDocument);
    this.upstreamAssets = extractTrackedAssets(this.upstreamDocument);
    this.newScripts = this.upstreamAssets
      .filter(attributeMatches('nodeName', 'SCRIPT'))
      .filter(noAttributeMatchesIn('src', this.activeAssets));

    this.newLinks = this.upstreamAssets
      .filter(attributeMatches('nodeName', 'LINK'))
      .filter(noAttributeMatchesIn('href', this.activeAssets));
  }

  hasChangedAnonymousAssets() {
    const anonymousUpstreamAssets = this.upstreamAssets
      .filter(datasetMatches(TRACKED_ATTRIBUTE_NAME, ANONYMOUS_TRACK_VALUE));
    const anonymousActiveAssets = this.activeAssets
      .filter(datasetMatches(TRACKED_ATTRIBUTE_NAME, ANONYMOUS_TRACK_VALUE));

    if (anonymousActiveAssets.length !== anonymousUpstreamAssets.length) {
      return true;
    }

    const noMatchingSrc = noAttributeMatchesIn('src', anonymousUpstreamAssets);
    const noMatchingHref = noAttributeMatchesIn('href', anonymousUpstreamAssets);

    return anonymousActiveAssets.some(node => noMatchingSrc(node) || noMatchingHref(node));
  }

  movingFromTrackedToUntracked() {
    return (this.upstreamAssets.length === 0) && (this.activeAssets.length > 0);
  }

  hasNamedAssetConflicts() {
    return this.newScripts
      .concat(this.newLinks)
      .filter(noDatasetMatches(TRACKED_ATTRIBUTE_NAME, ANONYMOUS_TRACK_VALUE))
      .some(datasetMatchesIn(TRACKED_ATTRIBUTE_NAME, this.activeAssets));
  }

  hasAssetConflicts() {
    return this.movingFromTrackedToUntracked() ||
      this.hasNamedAssetConflicts() ||
      this.hasChangedAnonymousAssets();
  }

  waitForAssets() {
    if (typeof resolvePreviousRequest === 'function') {
      resolvePreviousRequest({isCanceled: true});
    }

    return new Promise(resolve => {
      resolvePreviousRequest = resolve;
      return waitForCompleteDownloads()
        .then(this._insertNewAssets)
        .then(waitForCompleteDownloads)
        .then(resolve);
    });
  }

  _insertNewAssets() {
    updateLinkTags(this.activeDocument, this.newLinks);
    return updateScriptTags(this.activeDocument, this.newScripts);
  }
});
Cls.initClass();

var extractTrackedAssets = doc => [].slice.call(doc.querySelectorAll(TRACKED_ASSET_SELECTOR));

var attributeMatches = (attribute, value) => node => node[attribute] === value;

const attributeMatchesIn = (attribute, collection) => node => collection.some(nodeFromCollection => node[attribute] === nodeFromCollection[attribute]);

var noAttributeMatchesIn = (attribute, collection) => node => !collection.some(nodeFromCollection => node[attribute] === nodeFromCollection[attribute]);

var datasetMatches = (attribute, value) => node => node.dataset[attribute] === value;

var noDatasetMatches = (attribute, value) => node => node.dataset[attribute] !== value;

var datasetMatchesIn = (attribute, collection) => (function(node) {
  const value = node.dataset[attribute];
  return collection.some(datasetMatches(attribute, value));
});

const noDatasetMatchesIn = (attribute, collection) => (function(node) {
  const value = node.dataset[attribute];
  return !collection.some(datasetMatches(attribute, value));
});

var updateLinkTags = (activeDocument, newLinks) => // style tag load events don't work in all browsers
// as such we just hope they load ¯\_(ツ)_/¯
newLinks.forEach(function(linkNode) {
  const newNode = linkNode.cloneNode();
  activeDocument.head.appendChild(newNode);
  return triggerEvent("page:after-link-inserted", newNode);
});

var updateScriptTags = function(activeDocument, newScripts) {
  let promise = Promise.resolve();
  newScripts.forEach(scriptNode => promise = promise.then(() => insertScript(activeDocument, scriptNode)));
  return promise;
};

var insertScript = function(activeDocument, scriptNode) {
  const url = scriptNode.src;
  if (scriptPromises[url]) {
    return scriptPromises[url];
  }

  // Clone script tags to guarantee browser execution.
  const newNode = activeDocument.createElement('SCRIPT');
  for (var attr of Array.from(scriptNode.attributes)) { newNode.setAttribute(attr.name, attr.value); }
  newNode.appendChild(activeDocument.createTextNode(scriptNode.innerHTML));

  return scriptPromises[url] = new Promise(function(resolve) {
    var onAssetEvent = function(event) {
      if (event.type === 'error') { triggerEvent("page:#script-error", event); }
      newNode.removeEventListener('load', onAssetEvent);
      newNode.removeEventListener('error', onAssetEvent);
      return resolve();
    };

    newNode.addEventListener('load', onAssetEvent);
    newNode.addEventListener('error', onAssetEvent);
    activeDocument.head.appendChild(newNode);
    return triggerEvent("page:after-script-inserted", newNode);
  });
};
