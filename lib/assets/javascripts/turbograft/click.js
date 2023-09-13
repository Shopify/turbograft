// The Click class handles clicked links, verifying if Turbolinks should
// take control by inspecting both the event and the link. If it should,
// the page change process is initiated. If not, control is passed back
// to the browser for default functionality.
window.Click = class Click {
  static installHandlerLast(event) {
    if (!event.defaultPrevented) {
      document.removeEventListener('click', Click.handle, false);
      document.addEventListener('click', Click.handle, false);
    }
  }

  static handle(event) {
    return new Click(event);
  }

  constructor(event) {
    this.event = event;
    if (this.event.defaultPrevented) { return; }
    this._extractLink();
    if (this._validForTurbolinks()) {
      Turbolinks.visit(this.link.href);
      this.event.preventDefault();
    }
  }

  _extractLink() {
    let link = this.event.target;
    while (!!link.parentNode && (link.nodeName !== 'A')) { link = link.parentNode; }
    if ((link.nodeName === 'A') && (link.href.length !== 0)) { this.link = new Link(link); }
  }

  _validForTurbolinks() {
    return (this.link != null) && !this.link.shouldIgnore() && !this._nonStandardClick();
  }

  _nonStandardClick() {
    return (this.event.which > 1) ||
      this.event.metaKey ||
      this.event.ctrlKey ||
      this.event.shiftKey ||
      this.event.altKey;
  }
};
