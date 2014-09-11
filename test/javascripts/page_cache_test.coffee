describe 'PageCache', ->
  beforeEach ->
    @subject = new PageCache()

  it 'default cache size is 10', ->
    assert.equal 10, @subject.cacheSize

  it 'can set a new cache size', ->
    @subject.setCacheSize(15)
    assert.equal 15, @subject.cacheSize

    @subject.setCacheSize("13")
    assert.equal 13, @subject.cacheSize

  it 'can add to the cache', ->
    @subject.set("foo", {m: 'hi'})
    assert.deepEqual 'hi', @subject.get("foo").m

  it 'can get size of cache', ->
    @subject.set("foo", {m: 'hi'})
    @subject.set("fooz", {m: 'hi'})
    assert.equal 2, @subject.length()

  it 'cannot reference cache directly', ->
    assert.equal undefined, @subject.storage

  it 'will add a cachedAt timestamp when the object enters the cache', ->
    @subject.set("foo", {bar: 'baz'})

    result = @subject.get("foo")
    assert /^[\d]+$/.test(result.cachedAt.toString())

  it 'will evict older entries from cache if the cache exceeds the limit', ->
    @subject.setCacheSize(2)
    @subject.set("foo", {m: 'hi'})
    @subject.set("bar", {m: 'hey'})
    @subject.set("baz", {m: 'hello'})

    assert 2, @subject.length()
    assert.equal null, @subject.get("foo")
    assert 'hey', @subject.get("bar").m
    assert 'hello', @subject.get("baz").m

  it 'will keep the newest member added to the cache, if the same key is added twice', ->
    @subject.set("foo", {m: 'hi'})
    @subject.set("foo", {m: 'bar'})

    assert.equal "bar", @subject.get("foo").m
