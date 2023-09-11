/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
TurboGraft.Document = {
  create(html) {
    let doc;
    if (/<(html|body)/i.test(html)) {
      doc = document.documentElement.cloneNode();
      doc.innerHTML = html;
    } else {
      doc = document.documentElement.cloneNode(true);
      doc.querySelector('body').innerHTML = html;
    }
    doc.head = doc.querySelector('head');
    doc.body = doc.querySelector('body');
    return doc;
  }
};
