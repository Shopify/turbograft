window.fakeScript = (src) ->
  listeners = []
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
      return if eventName != 'load'
      listeners.push(listener)

    fireLoaded: () ->
      listener({type: 'load'}) for listener in listeners
      new Promise (resolve) ->
        node.isLoaded = true
        setTimeout -> resolve(node)

    removeEventListener: () -> {}
  }
