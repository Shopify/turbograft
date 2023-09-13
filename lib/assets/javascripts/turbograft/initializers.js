/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const hasClass = (node, search) => node.classList.contains(search);

const nodeIsDisabled = node => node.getAttribute('disabled') || hasClass(node, 'disabled');

const setupRemoteFromTarget = function(target, httpRequestType, form = null) {
  const httpUrl = target.getAttribute('href') || target.getAttribute('action');

  if (!httpUrl) { throw new Error(`Turbograft developer error: You did not provide a URL ('${urlAttribute}' attribute) for data-tg-remote`); }

  if (TurboGraft.getTGAttribute(target, "remote-once")) {
    TurboGraft.removeTGAttribute(target, "remote-once");
    TurboGraft.removeTGAttribute(target, "tg-remote");
  }

  const options = {
    httpRequestType,
    httpUrl,
    fullRefresh: (TurboGraft.getTGAttribute(target, 'full-refresh') != null),
    refreshOnSuccess: TurboGraft.getTGAttribute(target, 'refresh-on-success'),
    refreshOnSuccessExcept: TurboGraft.getTGAttribute(target, 'full-refresh-on-success-except'),
    refreshOnError: TurboGraft.getTGAttribute(target, 'refresh-on-error'),
    refreshOnErrorExcept: TurboGraft.getTGAttribute(target, 'full-refresh-on-error-except')
  };

  return new TurboGraft.Remote(options, form, target);
};

TurboGraft.handlers.remoteMethodHandler = function(ev) {
  const target = ev.clickTarget;
  const httpRequestType = TurboGraft.getTGAttribute(target, 'tg-remote');

  if (!httpRequestType) { return; }
  ev.preventDefault();

  const remote = setupRemoteFromTarget(target, httpRequestType);
  remote.submit();
};

TurboGraft.handlers.remoteFormHandler = function(ev) {
  const {
    target
  } = ev;
  const method = target.getAttribute('method');

  if (!TurboGraft.hasTGAttribute(target, 'tg-remote')) { return; }
  ev.preventDefault();

  const remote = setupRemoteFromTarget(target, method, target);
  remote.submit();
};

const documentListenerForButtons = function(eventType, handler, useCapture) {
  if (useCapture == null) { useCapture = false; }
  return document.addEventListener(eventType, function(ev) {
    let {
      target
    } = ev;

    while ((target !== document) && (target != null)) {
      if ((target.nodeName === "A") || (target.nodeName === "BUTTON")) {
        var isNodeDisabled = nodeIsDisabled(target);
        if (isNodeDisabled) { ev.preventDefault(); }
        if (!isNodeDisabled) {
          ev.clickTarget = target;
          handler(ev);
          return;
        }
      }

      target = target.parentNode;
    }
  });
};

documentListenerForButtons('click', TurboGraft.handlers.remoteMethodHandler, true);

document.addEventListener("submit", ev => TurboGraft.handlers.remoteFormHandler(ev));
