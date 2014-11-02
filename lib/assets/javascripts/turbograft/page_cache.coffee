class window.PageCache
  storage = {}
  simultaneousAdditionOffset = 0
  constructor: (@cacheSize = 10) ->
    storage = {}
    return this

  get: (key) ->
    storage[key]

  set: (key, value) ->
    if typeof value != "object"
      throw "Developer error: You must store objects in this cache"

    value['cachedAt'] = new Date().getTime() + (simultaneousAdditionOffset+=1)

    storage[key] = value
    @constrain()

  clear: ->
    storage = {}

  setCacheSize: (newSize) ->
    if /^[\d]+$/.test(newSize)
      @cacheSize = parseInt(newSize, 10)
      @constrain()
    else
      throw "Developer error: Invalid parameter '#{newSize}' for PageCache; must be integer"

  constrain: ->
    pageCacheKeys = Object.keys storage

    cacheTimesRecentFirst = pageCacheKeys.map (url) =>
      storage[url].cachedAt
    .sort (a, b) -> b - a

    for key in pageCacheKeys when storage[key].cachedAt <= cacheTimesRecentFirst[@cacheSize]
      triggerEvent 'page:expire', storage[key] # TODO: fix this global
      delete storage[key]

  length: ->
    Object.keys(storage).length
