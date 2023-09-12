/* The Link class derives from the ComponentUrl class, but is built from an
* existing link element.  Provides verification functionality for Turbolinks
* to use in determining whether it should process the link when clicked.
*/
window.Link = class Link extends ComponentUrl {
    HTML_EXTENSIONS = ['html'];

    static allowExtensions() {
      var extension, extensions, i, len;
      extensions = 1 <= arguments.length ? [].slice.call(arguments, 0) : [];
      for (i = 0, len = extensions.length; i < len; i++) {
        extension = extensions[i];
        Link.HTML_EXTENSIONS.push(extension);
      }
      return Link.HTML_EXTENSIONS;
    };

    constructor(link) {
      if (link.constructor === Link) {
        return link;
      }
      super(link.href, link);
    }

    shouldIgnore() {
      return this._crossOrigin() || this._anchored() || this._nonHtml() || this._optOut() || this._target();
    };

    _crossOrigin() {
      return this.origin !== (new ComponentUrl).origin;
    };

    _anchored() {
      var current;
      return ((this.hash && this.withoutHash()) === (current = new ComponentUrl).withoutHash()) || (this.href === current.href + '#');
    };

    _nonHtml() {
      return this.pathname.match(/\.[a-z]+$/g) && !this.pathname.match(new RegExp("\\.(?:" + (Link.HTML_EXTENSIONS.join('|')) + ")?$", 'g'));
    };

    _optOut() {
      var ignore, link;
      link = this.link;
      while (!(ignore || link === document || link === null)) {
        ignore = link.getAttribute('data-no-turbolink') != null;
        link = link.parentNode;
      }
      return ignore;
    };

    _target() {
      return this.link.target.length !== 0;
    };
};
