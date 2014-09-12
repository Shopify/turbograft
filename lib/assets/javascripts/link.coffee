# The Link class derives from the ComponentUrl class, but is built from an
# existing link element.  Provides verification functionality for Turbolinks
# to use in determining whether it should process the link when clicked.
class Link extends ComponentUrl
  @HTML_EXTENSIONS: ['html']

  @allowExtensions: (extensions...) ->
    Link.HTML_EXTENSIONS.push extension for extension in extensions
    Link.HTML_EXTENSIONS

  constructor: (@link) ->
    return @link if @link.constructor is Link
    @original = @link.href
    super

  shouldIgnore: ->
    @_crossOrigin() or
      @_anchored() or
      @_nonHtml() or
      @_optOut() or
      @_target()

  _crossOrigin: ->
    @origin isnt (new ComponentUrl).origin

  _anchored: ->
    ((@hash and @withoutHash()) is (current = new ComponentUrl).withoutHash()) or
      (@href is current.href + '#')

  _nonHtml: ->
    @pathname.match(/\.[a-z]+$/g) and not @pathname.match(new RegExp("\\.(?:#{Link.HTML_EXTENSIONS.join('|')})?$", 'g'))

  _optOut: ->
    link = @link
    until ignore or link is document
      ignore = link.getAttribute('data-no-turbolink')?
      link = link.parentNode
    ignore

  _target: ->
    @link.target.length isnt 0

window.Link = Link
