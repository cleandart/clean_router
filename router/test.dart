// Copyright (c) 2013, Samuel Hapak. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/unittest.dart';
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

  var route = new Route("/my-site/{var1}/{var2}/your-site/");

  test('Basic route matching', () {
    expect(route.match("/my-site/"), isNull);
    expect(
      route.match("/my-site/432/123/your-site/"),
      equals({'var1': '432', 'var2': '123'})
    );
    expect(
      route.match("/my_site/123/321/your-site/"),
      isNull
    );
  });
  test('Basic route generation', () {
    expect(
        route.getUrl({'var1': 'Hodnota', 'var2': 'Zloba'}),
        equals('/my-site/Hodnota/Zloba/your-site/')
    );
    expect(
        () => route.getUrl({'var1': 'Value'}),
        throwsFormatException
    );
  });

  test('Url escape', () {
    var params1 = {'var1': 'hello/dolly', 'var2': 'Ok'};
    var params2 = {'var1': 'hello darling', 'var2': 'Here/we/are'};
    expect(
      route.match(route.getUrl(params1)),
      equals(params1)
    );
    expect(
      route.match(route.getUrl(params2)),
      equals(params2)
    );
  });
}