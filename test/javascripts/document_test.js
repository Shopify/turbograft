/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
describe('TurboGraft.Document', function() {
  it('is defined', () => assert(TurboGraft.Document));

  return describe('@create', function() {
    it('returns a document with the given html when given a full html document', function() {
      const headHTML = '<link src="merp">';
      const bodyHTML = '<div>merp merp</div>';
      const template = `<html><head>${headHTML}</head><body>${bodyHTML}</body></html>`;

      const doc = TurboGraft.Document.create(template);
      assert.equal(doc.body.innerHTML, bodyHTML);
      return assert.equal(doc.head.innerHTML, headHTML);
    });

    it('returns a document with the given body when given only a body tag', function() {
      const bodyHTML = '<div>merp merp</div>';
      const template = `<body>${bodyHTML}</body>`;

      const doc = TurboGraft.Document.create(template);
      return assert.equal(doc.body.innerHTML, bodyHTML);
    });


    return it('returns a document with the given html at the root of the body when given a snippet', function() {
      const template = '<div>merp merp</div>';

      const doc = TurboGraft.Document.create(template);
      return assert.equal(doc.body.innerHTML, template);
    });
  });
});
