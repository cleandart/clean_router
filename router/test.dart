// Copyright (c) 2013, Samuel Hapak. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/unittest.dart';
import 'package:web_ui/observe.dart';
import 'lib/router.dart';

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

  test('Map returned from route matching is Map', () {
    expect(
      route1.match('/my-site/432/123/your-site/'),
      new isInstanceOf<Map>()
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
}