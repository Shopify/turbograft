/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
TurboGraft.Remote = class Remote {
  constructor(opts, form, target) {

    this.onSuccess = this.onSuccess.bind(this);
    this.onError = this.onError.bind(this);
    this.opts = opts;
    this.initiator = form || target;

    this.actualRequestType = (this.opts.httpRequestType != null ? this.opts.httpRequestType.toLowerCase() : undefined) === 'get' ? 'GET' : 'POST';
    this.useNativeEncoding = this.opts.useNativeEncoding;

    this.formData = this.createPayload(form);

    if (this.opts.refreshOnSuccess) { this.refreshOnSuccess       = this.opts.refreshOnSuccess.split(" "); }
    if (this.opts.refreshOnSuccessExcept) { this.refreshOnSuccessExcept = this.opts.refreshOnSuccessExcept.split(" "); }
    if (this.opts.refreshOnError) { this.refreshOnError         = this.opts.refreshOnError.split(" "); }
    if (this.opts.refreshOnErrorExcept) { this.refreshOnErrorExcept   = this.opts.refreshOnErrorExcept.split(" "); }

    const xhr = new XMLHttpRequest;
    if (this.actualRequestType === 'GET') {
      const url = this.formData ? this.opts.httpUrl + `?${this.formData}` : this.opts.httpUrl;
      xhr.open(this.actualRequestType, url, true);
    } else {
      xhr.open(this.actualRequestType, this.opts.httpUrl, true);
    }
    xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
    xhr.setRequestHeader('Accept', 'text/html, application/xhtml+xml, application/xml');
    if (this.contentType) { xhr.setRequestHeader("Content-Type", this.contentType); }
    xhr.setRequestHeader('X-XHR-Referer', document.location.href);

    const csrfToken = CSRFToken.get().token;
    if (csrfToken) { xhr.setRequestHeader('X-CSRF-Token', csrfToken); }

    triggerEventFor('turbograft:remote:init', this.initiator, {xhr, initiator: this.initiator});

    xhr.addEventListener('loadstart', () => {
      return triggerEventFor('turbograft:remote:start', this.initiator,
        {xhr});
    });

    xhr.addEventListener('error', this.onError);
    xhr.addEventListener('load', event => {
      if (xhr.status < 400) {
        return this.onSuccess(event);
      } else {
        return this.onError(event);
      }
    });

    xhr.addEventListener('loadend', () => {
      if (typeof this.opts.done === 'function') {
        this.opts.done();
      }
      return triggerEventFor('turbograft:remote:always', this.initiator, {
        initiator: this.initiator,
        xhr
      }
      );
    });

    this.xhr = xhr;
  }

  submit() {
    return this.xhr.send(this.formData);
  }

  createPayload(form) {
    let formData;
    if (form) {
      if (this.useNativeEncoding || (form.querySelectorAll("[type='file'][name]").length > 0)) {
        formData = this.nativeEncodeForm(form);
      } else { // for much smaller payloads
        formData = this.uriEncodeForm(form);
      }
    } else {
      formData = '';
    }

    if (!(formData instanceof FormData)) {
      this.contentType = "application/x-www-form-urlencoded; charset=UTF-8";
      if ((formData.indexOf("_method") === -1) && this.opts.httpRequestType && (this.actualRequestType !== 'GET')) { formData = this.formAppend(formData, "_method", this.opts.httpRequestType); }
    }

    return formData;
  }

  formAppend(uriEncoded, key, value) {
    if (uriEncoded.length) { uriEncoded += "&"; }
    return uriEncoded += `${encodeURIComponent(key)}=${encodeURIComponent(value)}`;
  }

  uriEncodeForm(form) {
    let formData = "";
    this._iterateOverFormInputs(form, input => {
      return formData = this.formAppend(formData, input.name, input.value);
    });
    return formData;
  }

  formDataAppend(formData, input) {
    if (input.type === 'file') {
      for (var file of Array.from(input.files)) {
        formData.append(input.name, file);
      }
    } else {
      formData.append(input.name, input.value);
    }
    return formData;
  }

  nativeEncodeForm(form) {
    let formData = new FormData;
    this._iterateOverFormInputs(form, input => {
      return formData = this.formDataAppend(formData, input);
    });
    return formData;
  }

  _iterateOverFormInputs(form, callback) {
    const inputs = this._enabledInputs(form);
    return (() => {
      const result = [];
      for (var input of Array.from(inputs)) {
        var inputEnabled = !input.disabled;
        var radioOrCheck = ((input.type === 'checkbox') || (input.type === 'radio'));

        if (inputEnabled && input.name) {
          if ((radioOrCheck && input.checked) || !radioOrCheck) {
            result.push(callback(input));
          } else {
            result.push(undefined);
          }
        } else {
          result.push(undefined);
        }
      }
      return result;
    })();
  }

  _enabledInputs(form) {
    const selector = "input:not([type='reset']):not([type='button']):not([type='submit']):not([type='image']), select, textarea";
    const inputs = Array.prototype.slice.call(form.querySelectorAll(selector));
    const disabledNodes = Array.prototype.slice.call(TurboGraft.querySelectorAllTGAttribute(form, 'tg-remote-noserialize'));

    if (!disabledNodes.length) { return inputs; }

    let disabledInputs = disabledNodes;
    for (var node of Array.from(disabledNodes)) {
      disabledInputs = disabledInputs.concat(Array.prototype.slice.call(node.querySelectorAll(selector)));
    }

    const enabledInputs = [];
    for (var input of Array.from(inputs)) {
      if (disabledInputs.indexOf(input) < 0) {
        enabledInputs.push(input);
      }
    }
    return enabledInputs;
  }

  onSuccess(ev) {
    let redirect;
    if (typeof this.opts.success === 'function') {
      this.opts.success();
    }

    const xhr = ev.target;
    triggerEventFor('turbograft:remote:success', this.initiator, {
      initiator: this.initiator,
      xhr
    }
    );

    if (redirect = xhr.getResponseHeader('X-Next-Redirect')) {
      Page.visit(redirect, {reload: true});
      return;
    }

    if (!TurboGraft.hasTGAttribute(this.initiator, 'tg-remote-norefresh')) {
      if (this.opts.fullRefresh && this.refreshOnSuccess) {
        return Page.refresh({onlyKeys: this.refreshOnSuccess});
      } else if (this.opts.fullRefresh) {
        return Page.refresh();
      } else if (this.refreshOnSuccess) {
        return Page.refresh({
          response: xhr,
          onlyKeys: this.refreshOnSuccess
        });
      } else if (this.refreshOnSuccessExcept) {
        return Page.refresh({
          response: xhr,
          exceptKeys: this.refreshOnSuccessExcept
        });
      } else {
        return Page.refresh({
          response: xhr
        });
      }
    }
  }

  onError(ev) {
    if (typeof this.opts.fail === 'function') {
      this.opts.fail();
    }

    const xhr = ev.target;
    triggerEventFor('turbograft:remote:fail', this.initiator, {
      initiator: this.initiator,
      xhr
    }
    );

    if (TurboGraft.hasTGAttribute(this.initiator, 'tg-remote-norefresh')) {
      return triggerEventFor('turbograft:remote:fail:unhandled', this.initiator,
        {xhr});
    } else {
      if (this.opts.fullRefresh && this.refreshOnError) {
        return Page.refresh({onlyKeys: this.refreshOnError});
      } else if (this.opts.fullRefresh) {
        return Page.refresh();
      } else if (this.refreshOnError) {
        return Page.refresh({
          response: xhr,
          onlyKeys: this.refreshOnError
        });
      } else if (this.refreshOnErrorExcept) {
        return Page.refresh({
          response: xhr,
          exceptKeys: this.refreshOnErrorExcept
        });
      } else {
        return triggerEventFor('turbograft:remote:fail:unhandled', this.initiator,
          {xhr});
      }
    }
  }
};
