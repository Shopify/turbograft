/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
TurboGraft.Response = class Response {
  constructor(xhr, intendedURL) {
    let redirectedTo;
    this.xhr = xhr;
    if (intendedURL && (intendedURL.withoutHash() !== this.xhr.responseURL)) {
      redirectedTo = this.xhr.responseURL;
    } else {
      redirectedTo = this.xhr.getResponseHeader('X-XHR-Redirected-To');
    }

    this.finalURL = redirectedTo || intendedURL;
  }

  valid() { return this.hasRenderableHttpStatus() && this.hasValidContent(); }

  document() {
    if (this.valid()) {
      return TurboGraft.Document.create(this.xhr.responseText);
    }
  }

  hasRenderableHttpStatus() {
    if (this.xhr.status === 422) { return true; } // we want to render form validations
    return !(400 <= this.xhr.status && this.xhr.status < 600);
  }

  hasValidContent() {
    let contentType;
    if (contentType = this.xhr.getResponseHeader('Content-Type')) {
      return contentType.match(/^(?:text\/html|application\/xhtml\+xml|application\/xml)(?:;|$)/);
    } else {
      throw new Error(`Error encountered for XHR Response: ${this}`);
    }
  }

  toString() {
    return `URL: ${this.xhr.responseURL}, ` +
    `ReadyState: ${this.xhr.readyState}, ` +
    `Headers: ${this.xhr.getAllResponseHeaders()}`;
  }
};

TurboGraft.location = () => location.href;
