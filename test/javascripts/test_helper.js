//= require support/sinon
//= require support/chai
//= require support/sinon-chai
//= require fixtures/js/routes
//= require vendor/promise-polyfill/promise
//= require application

expect = chai.expect;
assert = chai.assert;
spy = sinon.spy;
mock = sinon.mock;
stub = sinon.stub;

mocha.setup('tdd')
sinon.assert.expose(chai.assert, {prefix: ''});
chai.config.truncateThreshold = 9999;
