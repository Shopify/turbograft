/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
describe('CSRFToken', function() {
  beforeEach(function() {
    const $meta = $("<meta>").attr("name", "csrf-token").attr("id", "meta-tag").attr("content", "original");
    $("meta[name='csrf-token']").remove();
    return $("head").append($meta);
  });

  afterEach(() => $("#meta-tag").remove());

  it('can get the CSRF token', () => assert.equal(CSRFToken.get().token, "original"));

  return it('can update the CSRF token', function() {
    CSRFToken.update("updated_value");
    return assert.equal(CSRFToken.get().token, "updated_value");
  });
});
