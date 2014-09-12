Turbomodules
-----

This project rocks and uses MIT-LICENSE.

# Developing JavaScript

## Install dependencies using npm

1. `npm install`
2. `npm install -g testem browserify coffee-script`

## Building a 1-file Turbomodules package

1. `make .app`
2. The concatenated file is available at `lib/turbomodules.js`

## Testing JavaScript

- Run `testem ci` to run tests across many browsers
- Run `testem` and visit the URL provided to debug tests in your preferred browser
