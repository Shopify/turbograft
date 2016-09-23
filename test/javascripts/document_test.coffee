describe 'TurboGraft.Document', ->
  it 'is defined', ->
    assert(TurboGraft.Document)

  describe '@create', ->
    it 'returns a document with the given html when given a full html document', ->
      headHTML = '<link src="merp">'
      bodyHTML = '<div>merp merp</div>'
      template = "<html><head>#{headHTML}</head><body>#{bodyHTML}</body></html>"

      doc = TurboGraft.Document.create(template)
      assert.equal(doc.body.innerHTML, bodyHTML)
      assert.equal(doc.head.innerHTML, headHTML)

    it 'returns a document with the given body when given only a body tag', ->
      bodyHTML = '<div>merp merp</div>'
      template = "<body>#{bodyHTML}</body>"

      doc = TurboGraft.Document.create(template)
      assert.equal(doc.body.innerHTML, bodyHTML)


    it 'returns a document with the given html at the root of the body when given a snippet', ->
      template = '<div>merp merp</div>'

      doc = TurboGraft.Document.create(template)
      assert.equal(doc.body.innerHTML, template)
