'use strict';

use('sake-bundle');

use('sake-linked');

use('sake-outdated');

use('sake-test');

use('sake-version');

task('start', 'start project', ['build'], function () {
  return require('./app.js');
});

task('build', 'build project', ['build:js']);

task('build:js', 'build js', function () {
  if (running('build')) {
    return;
  }
  return bundle.write({
    cache: false,
    output: 'app.js',
    entry: 'src/app.coffee',
    compilers: {
      coffee: {
        version: 2
      }
    }
  })["catch"](function (err) {
    return console.error(err);
  });
});