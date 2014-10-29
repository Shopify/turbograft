describe 'CSRFToken', ->
  beforeEach ->
    $meta = $("<meta>").attr("name", "csrf-token").attr("id", "meta-tag").attr("content", "original")
    $("meta[name='csrf-token']").remove()
    $("head").append($meta)

  afterEach ->
    $("#meta-tag").remove()

  it 'can get the CSRF token', ->
    assert.equal CSRFToken.get().token, "original"

  it 'can update the CSRF token', ->
    CSRFToken.update("updated_value")
    assert.equal CSRFToken.get().token, "updated_value"
