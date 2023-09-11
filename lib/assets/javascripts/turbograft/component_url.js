/* The ComponentUrl class converts a basic URL string into an object
 * that behaves similarly to document.location.
 *
 * If an instance is created from a relative URL, the current document
 * is used to fill in the missing attributes (protocol, host, port).
 */
window.ComponentUrl = (function() {
  function ComponentUrl(original, link) {
    if (original == null) {
      original = document.location.href;
    }
    if (link == null) {
      link = document.createElement('a');
    }
    if (original.constructor === ComponentUrl) {
      return original;
    }
    this.original = original;
    this.link = link;
    this._parse();
  }

  ComponentUrl.prototype.withoutHash = function() {
    return this.href.replace(this.hash, '');
  };

  // Intention revealing function alias
  ComponentUrl.prototype.withoutHashForIE10compatibility = function() {
    return this.withoutHash();
  };

  ComponentUrl.prototype.hasNoHash = function() {
    return this.hash.length === 0;
  };

  ComponentUrl.prototype._parse = function() {
    this.link.href = this.original;
    this.href = this.link.href;
    this.protocol = this.link.protocol;
    this.host = this.link.host;
    this.hostname = this.link.hostname
    this.port = this.link.port;
    this.pathname = this.link.pathname;
    this.search = this.link.search;
    this.hash = this.link.hash;
    this.origin = [this.protocol, '//', this.hostname].join('');
    if (this.port.length !== 0) {
      this.origin += ":" + this.port;
    }
    this.relative = [this.pathname, this.search, this.hash].join('');
    return this.absolute = this.href;
  };

  return ComponentUrl;

})();
