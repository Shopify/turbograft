[1mdiff --git a/lib/assets/javascripts/turbograft/turbolinks.coffee b/lib/assets/javascripts/turbograft/turbolinks.coffee[m
[1mindex 6943b74..7785684 100644[m
[1m--- a/lib/assets/javascripts/turbograft/turbolinks.coffee[m
[1m+++ b/lib/assets/javascripts/turbograft/turbolinks.coffee[m
[36m@@ -58,7 +58,6 @@[m [mclass window.Turbolinks[m
   loadedAssets = null[m
   referer = null[m
 [m
[31m-  # fetch = (url, partialReplace = false, replaceContents = [], callback) ->[m
   fetch = (url, options = {}, callback) ->[m
     return if pageChangePrevented(url)[m
     url = new ComponentUrl url[m
[36m@@ -66,12 +65,12 @@[m [mclass window.Turbolinks[m
     rememberReferer()[m
 [m
     options.partialReplace ?= false[m
[31m-    options.replaceContents ?= [][m
[31m-[m
[31m-    fetchReplacement url, options.partialReplace, ->[m
[32m+[m[32m    options.onlyKeys ?= [][m
[32m+[m[32m    options.onLoadFunction = ->[m
       resetScrollPosition() unless options.onlyKeys.length[m
       callback?()[m
[31m-    , options.onlyKeys[m
[32m+[m
[32m+[m[32m    fetchReplacement url, options.partialReplace, options.onLoadFunction, options.onlyKeys[m
 [m
   @pushState: (state, title, url) ->[m
     window.history.pushState(state, title, url)[m
