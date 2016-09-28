window.fakeScript = (src) ->
  listeners = {load: [], error: []}
  node = {
    'data-turbolinks-track': src
    attributes: [{name: 'src', value: src}]
    isLoaded: false
    src: src
    nodeName: 'SCRIPT'

    appendChild: () -> {}

    setAttribute: (name, value) ->
      if name == 'src'
        @src = value
      @attributes.push({name: name, value: value})

    addEventListener: (eventName, listener) ->
      listeners[eventName].push(listener)

    fireError: () ->
      listener({type: 'error'}) for listener in listeners['error']
      new Promise (resolve) ->
        node.hasError = true
        setTimeout -> resolve(node)

    fireLoaded: () ->
      listener({type: 'load'}) for listener in listeners['load']
      new Promise (resolve) ->
        node.isLoaded = true
        setTimeout -> resolve(node)

    removeEventListener: () -> {}
  }
