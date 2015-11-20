#= require_self
#= require_tree ./turbograft

window.TurboGraft ?= { handlers: {} }

TurboGraft.tgAttribute = (attr) ->
  tgAttr = if attr[0...3] == 'tg-'
    "data-#{attr}"
  else
    "data-tg-#{attr}"

TurboGraft.getTGAttribute = (node, attr) ->
  tgAttr = TurboGraft.tgAttribute(attr)
  node.getAttribute(tgAttr) || node.getAttribute(attr)

TurboGraft.removeTGAttribute = (node, attr) ->
  tgAttr = TurboGraft.tgAttribute(attr)
  node.removeAttribute(tgAttr)
  node.removeAttribute(attr)

TurboGraft.hasTGAttribute = (node, attr) ->
  tgAttr = TurboGraft.tgAttribute(attr)
  node.getAttribute(tgAttr)? || node.getAttribute(attr)?

TurboGraft.querySelectorAllTGAttribute = (node, attr, value = null) ->
  tgAttr = TurboGraft.tgAttribute(attr)
  if value
    node.querySelectorAll("[#{tgAttr}=#{value}], [#{attr}=#{value}]")
  else
    node.querySelectorAll("[#{tgAttr}], [#{attr}]")
