/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
//= require ./fake_script

window.fakeDocument = function(scriptSources) {
  const nodes = (Array.from(scriptSources).map((src) => fakeScript(src)));
  const newNodes = [];

  return {
    createdScripts: newNodes,
    head: {
      appendChild() { return {}; }
    },

    createElement() {
      const script = fakeScript();
      newNodes.push(script);
      return script;
    },

    createTextNode() { return {}; },

    querySelectorAll() { return nodes; }
  };
};
