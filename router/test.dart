// Copyright (c) 2013, Samuel Hapak. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/unittest.dart';
import 'package:unittest/mock.dart';
import 'lib/router.dart';
import 'dart:html';

class HistoryMock extends Mock implements History {}
class RouterMock extends Mock implements Router {}

void main() {
  test('Unsupported route format', () {
    expect(
      () => new Route("not-starting-with-backslash"),
      throwsFormatException
    );
    expect(
      () => new Route("/#some-chars-not-allowed"),
      throwsFormatException
    );
    expect(
      () => new Route("/some-chars/{not-allowed}/in/variable/"),
      throwsFormatException
    );
    expect(
      () => new Route("/variable-must-begin-with/{_alpha}/"),
      throwsFormatException
    );
  });

  var route1 = new Route("/my-site/{var1}/{var2}/your-site/");
  var route2 = new Route("/just/static/one");
  var route3 = new Route("/route/{one_parameter}/");

  test('Basic route matching', () {
    expect(route1.match("/my-site/"), isNull);
    expect(
      route1.match("/my-site/432/123/your-site/"),
      equals({'var1': '432', 'var2': '123'})
    );
    expect(
      route1.match("/my_site/123/321/your-site/"),
      isNull
    );
  });
  test('Basic route generation', () {
    expect(
        route1.path({'var1': 'Hodnota', 'var2': 'Zloba'}),
        equals('/my-site/Hodnota/Zloba/your-site/')
    );
    expect(
        () => route1.path({'var1': 'Value'}),
        throwsFormatException
    );
  });

  test('Url escape', () {
    var params1 = {'var1': 'hello/dolly', 'var2': 'Ok'};
    var params2 = {'var1': 'hello darling', 'var2': 'Here/we/are'};
    expect(
      route1.match(route1.path(params1)),
      equals(params1)
    );
    expect(
      route1.match(route1.path(params2)),
      equals(params2)
    );
  });

  var router = new Router('http://www.google.com', {
    'my-site': route1,
    'static': route2,
    'one-param': route3,
  });

  test('Router route', () {
    expect(
      router.routePath('static', {}),
      equals('/just/static/one')
    );
    expect(
      router.routeUrl('static', {}),
      equals('http://www.google.com/just/static/one')
    );
    expect(
      router.routePath('my-site', {'var1': 'value1', 'var2': 'value2'}),
      equals('/my-site/value1/value2/your-site/')
    );
    expect(
      router.routeUrl('my-site', {'var1': 'value1', 'var2': 'value2'}),
      equals('http://www.google.com/my-site/value1/value2/your-site/')
    );
    expect(
      router.routePath('one-param', {'one_parameter': 'some_value'}),
      equals('/route/some_value/')
    );
    expect(
      router.routeUrl('one-param', {'one_parameter': 'some_value'}),
      equals('http://www.google.com/route/some_value/')
    );

  });

  test('Router route with undefined route throws Error', () {
    expect(
      () => router.routePath('invalid-route', {}),
      throwsArgumentError
    );

  });

  test('Route matching', () {
    var match = router.match('/my-site/value1/value2/your-site/');
    expect(match[0], equals('my-site'));
    expect(match[1], equals({'var1': 'value1', 'var2': 'value2'}));
  });

  test('Route matching undefined route throws Error', () {
    expect(
        () => router.match('/invalid-route'),
        throwsArgumentError
    );
  });

  test('Simple transition unloads old and loads new view.', () {
    var oldView = new Mock();
    var newView = new Mock();
    var parameters = {'var1': 'value1', 'var2': 'value2'};

    simpleTransition(oldView, newView, parameters);

    oldView.getLogs(callsTo('unload')).verify(happenedOnce);
    newView.getLogs(callsTo('load', parameters)).verify(happenedOnce);
  });

  test('Simple transition does not call unload on null view.', () {
    var newView = new Mock();
    var parameters = {'var1': 'value1', 'var2': 'value2'};

    simpleTransition(null, newView, parameters);

    newView.getLogs(callsTo('load', parameters)).verify(happenedOnce);
  });

  test('PageNavigator can navigate to url and call transitionHandler', () {
    var data = [
      {
        'url': '/sample/url/',
        'route': 'route1',
        'params': {'var1': 'value1'},
        'view': new Mock(),
      },
      {
        'url': '/other/url/',
        'route': 'route2',
        'params': {'var2': 'value2'},
        'view': new Mock(),
      },
    ];
    var history = new HistoryMock();
    var router = new RouterMock();
    var views = {};
    var transitions;
    var transitionHandler = (oldView, newView, parameters)
        => transitions = [oldView, newView, parameters];

    for (var sample in data) {
      router.when(callsTo('match', sample['url']))
            .alwaysReturn([sample['route'], sample['params']]);
      views[sample['route']] = sample['view'];
    }

    var navigator = new PageNavigator(
        history, router, views, transitionHandler);

    navigator.navigate(data[0]['url']);
    expect(transitions, equals([null, data[0]['view'], data[0]['params']]));
    navigator.navigate(data[1]['url']);
    expect(transitions,
        equals([data[0]['view'], data[1]['view'], data[1]['params']])
    );

    history.getLogs(callsTo('pushState')).verify(happenedExactly(2));

  });


}