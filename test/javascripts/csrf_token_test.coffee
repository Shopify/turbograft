describe 'CSRFToken', ->

  beforeEach ->
    $csrfToken = $("<meta name='csrf-token' content='foo'></meta>")
    @csrfTokenNode = $csrfToken[0]
    $("body").append $csrfToken

    @subject = CSRFToken

  afterEach ->
    $("meta[name='csrf-token']").remove()

  describe '#get', ->
    it 'returns the node and the value of the token', ->
      result = @subject.get()
      assert.equal "foo", result.token
      assert.equal @csrfTokenNode, result.node

  describe '#update', ->
    it 'sets the value of the token to a new value', ->
      @subject.update("bar")
      result = @subject.get()
      assert.equal "bar", result.token
