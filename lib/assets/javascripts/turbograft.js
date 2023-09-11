//= require_self
//= require_tree ./turbograft

if (window.TurboGraft == null) { window.TurboGraft = { handlers: {} }; }

TurboGraft.tgAttribute = function(attr) {
  if (attr.slice(0, 3) === 'tg-') {
    return `data-${attr}`;
  } else {
    return `data-tg-${attr}`;
  }
};

TurboGraft.getTGAttribute = function(node, attr) {
  const tgAttr = TurboGraft.tgAttribute(attr);
  return node.getAttribute(tgAttr) || node.getAttribute(attr);
};

TurboGraft.removeTGAttribute = function(node, attr) {
  const tgAttr = TurboGraft.tgAttribute(attr);
  node.removeAttribute(tgAttr);
  node.removeAttribute(attr);
};

TurboGraft.hasTGAttribute = function(node, attr) {
  const tgAttr = TurboGraft.tgAttribute(attr);
  return node.hasAttribute(tgAttr) || node.hasAttribute(attr);
};

TurboGraft.querySelectorAllTGAttribute = function(node, attr, value = null) {
  const tgAttr = TurboGraft.tgAttribute(attr);
  if (value) {
    return node.querySelectorAll(`[${tgAttr}=${value}], [${attr}=${value}]`);
  } else {
    return node.querySelectorAll(`[${tgAttr}], [${attr}]`);
  }
};
