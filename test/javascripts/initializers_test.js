/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
describe('Initializers', function() {

  // can't figure out why this doesn't work:
  describe('tg-remote on forms', function() {
    beforeEach(function() {
      return this.Remote = stub(TurboGraft, "Remote").returns({submit() {}});
    });

    afterEach(function() {
      return this.Remote.restore();
    });

    return it('creates a remote based on the options passed in', function() {
      const $form = $("<form>")
        .attr("tg-remote", "true")
        .attr("method", "put")
        .attr("refresh-on-success", "foo")
        .attr("refresh-on-error", "bar")
        .attr("full-refresh-on-error-except", "zar")
        .attr("full-refresh-on-success-except", "zap")
        .attr("action", "somewhere");
      $form.append("<input type='submit'>");

      $("body").append($form);
      $form.find("input").trigger("click");

      assert.called(this.Remote);
      assert.calledWith(this.Remote, {
        httpRequestType: "put",
        httpUrl: "somewhere",
        fullRefresh: false,
        refreshOnSuccess: "foo",
        refreshOnSuccessExcept: "zap",
        refreshOnError: "bar",
        refreshOnErrorExcept: "zar"
      }
      );
      return $form.remove();
    });
  });

  return describe('tg-remote on links', function() {
    beforeEach(function() {
      return this.Remote = stub(TurboGraft, "Remote").returns({submit() {}});
    });

    afterEach(function() {
      return this.Remote.restore();
    });

    it('creates a remote based on the options passed in', function() {
      const $link = $('<a>')
        .attr('tg-remote', 'GET')
        .attr('refresh-on-success', 'foo')
        .attr('refresh-on-error', 'bar')
        .attr('full-refresh-on-error-except', 'zar')
        .attr('full-refresh-on-success-except', 'zap')
        .attr('href', 'somewhere');

      $('body').append($link);
      $link[0].click();
      assert.called(this.Remote);
      return assert.calledWith(this.Remote, {
        httpRequestType: 'GET',
        httpUrl: 'somewhere',
        fullRefresh: false,
        refreshOnSuccess: 'foo',
        refreshOnSuccessExcept: 'zap',
        refreshOnError: 'bar',
        refreshOnErrorExcept: 'zar'
      }
      );
    });

    it('passes through null for missing refresh-on-success', function() {
      const $link = $("<a>")
        .attr("tg-remote", "GET")
        .attr("refresh-on-error", "bar")
        .attr("href", "somewhere");

      $("body").append($link);
      $link[0].click();
      assert.called(this.Remote);
      return assert.calledWith(this.Remote, {
        httpRequestType: "GET",
        httpUrl: "somewhere",
        fullRefresh: false,
        refreshOnSuccess: null,
        refreshOnSuccessExcept: null,
        refreshOnError: "bar",
        refreshOnErrorExcept: null
      }
      );
    });

    it('respects tg-remote supplied', function() {
      const $link = $("<a>")
        .attr("tg-remote", "PATCH")
        .attr("refresh-on-error", "bar")
        .attr("href", "somewhere");

      $("body").append($link);
      $link[0].click();
      assert.called(this.Remote);
      return assert.calledWith(this.Remote, {
        httpRequestType: "PATCH",
        httpUrl: "somewhere",
        fullRefresh: false,
        refreshOnSuccess: null,
        refreshOnSuccessExcept: null,
        refreshOnError: "bar",
        refreshOnErrorExcept: null
      }
      );
    });

    it('passes through null for missing refresh-on-error', function() {
      const $link = $("<a>")
        .attr("tg-remote", "GET")
        .attr("refresh-on-success", "foo")
        .attr("href", "somewhere");

      $("body").append($link);
      $link[0].click();
      assert.called(this.Remote);
      return assert.calledWith(this.Remote, {
        httpRequestType: "GET",
        httpUrl: "somewhere",
        fullRefresh: false,
        refreshOnSuccess: "foo",
        refreshOnSuccessExcept: null,
        refreshOnError: null,
        refreshOnErrorExcept: null
      }
      );
    });

    it('passes through null for missing full-refresh-on-error-except', function() {
      const $link = $("<a>")
        .attr("tg-remote", "GET")
        .attr("full-refresh-on-error-except", "zew")
        .attr("href", "somewhere");

      $("body").append($link);
      $link[0].click();
      assert.called(this.Remote);
      return assert.calledWith(this.Remote, {
        httpRequestType: "GET",
        httpUrl: "somewhere",
        fullRefresh: false,
        refreshOnSuccess: null,
        refreshOnSuccessExcept: null,
        refreshOnError: null,
        refreshOnErrorExcept: 'zew'
      }
      );
    });

    it('respects full-refresh-on-success-except', function() {
      const $link = $("<a>")
        .attr("tg-remote", "GET")
        .attr("full-refresh-on-success-except", "zew")
        .attr("href", "somewhere");

      $("body").append($link);
      $link[0].click();
      assert.called(this.Remote);
      return assert.calledWith(this.Remote, {
        httpRequestType: "GET",
        httpUrl: "somewhere",
        fullRefresh: false,
        refreshOnSuccess: null,
        refreshOnSuccessExcept: 'zew',
        refreshOnError: null,
        refreshOnErrorExcept: null
      }
      );
    });

    it('respects full-refresh', function() {
      const $link = $("<a>")
        .attr("full-refresh", true)
        .attr("tg-remote", "GET")
        .attr("refresh-on-success", "foo")
        .attr("refresh-on-error", "bar")
        .attr("href", "somewhere");

      $("body").append($link);
      $link[0].click();
      assert.called(this.Remote);
      return assert.calledWith(this.Remote, {
        httpRequestType: "GET",
        httpUrl: "somewhere",
        fullRefresh: true,
        refreshOnSuccess: "foo",
        refreshOnSuccessExcept: null,
        refreshOnError: "bar",
        refreshOnErrorExcept: null
      }
      );
    });

    it('does nothing if disabled', function() {
      const $link = $("<a>")
        .attr("disabled", "disabled")
        .attr("tg-remote", "GET")
        .attr("refresh-on-success", "foo")
        .attr("refresh-on-error", "bar")
        .attr("href", "somewhere");

      $("body").append($link);
      $link[0].click();
      return assert.notCalled(this.Remote);
    });

    it('clicking on nodes inside of an <a> will bubble correctly', function() {
      const $link = $("<a><i>foo</i></a>")
        .attr("tg-remote", "PATCH")
        .attr("refresh-on-error", "bar")
        .attr("href", "somewhere");

      const $i = $link.find("i");

      $("body").append($link);
      $i[0].click();
      assert.called(this.Remote);
      assert.calledWith(this.Remote, {
        httpRequestType: "PATCH",
        httpUrl: "somewhere",
        fullRefresh: false,
        refreshOnSuccess: null,
        refreshOnSuccessExcept: null,
        refreshOnError: "bar",
        refreshOnErrorExcept: null
      }
      );

      return $link.remove();
    });

    return it('clicking on nodes inside of a <button> will bubble correctly', function() {
      const $link = $("<a><i><em><strong>foo</strong></em></i></a>")
        .attr("tg-remote", "PATCH")
        .attr("refresh-on-error", "bar")
        .attr("href", "somewhere");

      const $strong = $link.find("strong");

      $("body").append($link);
      $strong[0].click();
      assert.called(this.Remote);
      assert.calledWith(this.Remote, {
        httpRequestType: "PATCH",
        httpUrl: "somewhere",
        fullRefresh: false,
        refreshOnSuccess: null,
        refreshOnSuccessExcept: null,
        refreshOnError: "bar",
        refreshOnErrorExcept: null
      }
      );

      return $link.remove();
    });
  });
});
