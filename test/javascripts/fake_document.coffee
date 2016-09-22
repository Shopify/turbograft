#= require ./fake_script

window.fakeDocument = (scriptSources) ->
  nodes = (fakeScript(src) for src in scriptSources)
  newNodes = []

  return {
    createdScripts: newNodes
    head: {
      appendChild: () -> {}
    }

    createElement: () ->
      script = fakeScript()
      newNodes.push(script)
      script

    createTextNode: () -> {}

    querySelectorAll: -> nodes
  }
