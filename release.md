## Release instructions

1. Update `version.rb` to the correct version
2. `bundle install`
3. `bundle exec rake release`

## Remove old releases (only if they are failing)

```bash
gem install gemcutter
gem yank turbograft -v<version>
```
