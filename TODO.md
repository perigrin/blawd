# TODO

* Fix the Tests: They are horrifically stale and do not cover the
  general usage of most of the application now.
* Config -- I would like to use
  [Config::GitLike](http://search.cpan.org/dist/Config-GitLike/) to
  control the configuration stuff. This would live in the repo under a
  [Blawd] header or something like that.
* More Index types -- I want to be able to easily auto-create archive
  indexes for date ranges (Year, Month, etc) based on aggregating
  entries properly. It would be awesome to figure out a way to easily
  make this into strings we can store in the config
* Set the Main Index and RSS feed to filter on posts with a time >
  DateTime->now -- this will let us work on posts for a while and then
  have them "auto post"
* Pipe line of Renderers -- MultiMarkdown is designed to render (via
  xslt) into other formats, I'd like to be able to chain Renderer's
  together
* Plugin API -- I really would like something like Dist::Zilla's plugin
  architecture to be able to control how things are hooked together
