// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library commont_test;

import 'package:unittest/unittest.dart';
import '../lib/common.dart';

int main(){
  group('Route', () {
    test('unsupported format', () {
      expect(() => new Route(""), throwsFormatException);
      expect(() => new Route("not-starting-with-slash/"),throwsFormatException);
      expect(() => new Route("/not-ending-with-slash"),  throwsFormatException);
      expect(() => new Route("/#some-chars-not-allowed/"),throwsFormatException);
      expect(() => new Route("/?some-chars-not-allowed/"),throwsFormatException);
      expect(() => new Route("/!some-chars-not-allowed/"),throwsFormatException);
      expect(() => new Route("/.some-chars-not-allowed/"),throwsFormatException);
      expect(() => new Route("/{not_closed/"),           throwsFormatException);
      expect(() => new Route("/not_open}/"),             throwsFormatException);
      expect(() => new Route("/{{more-brackets}/"),      throwsFormatException);
      expect(() => new Route("/{more-brackets}}/"),      throwsFormatException);
      expect(() => new Route("/{more-asterisks}}/**"),      throwsFormatException);
    });

    test('supported format', () {
      expect(new Route("/"), isNot(isException));
      expect(new Route("//"), isNot(isException));
      expect(new Route("////////////////////////"), isNot(isException));
      expect(new Route("/{anything-here4!@#\$%^&*()\\\n}/"), isNot(isException));
      expect(new Route("/anytail/*"), isNot(isException));
    });

    test('matching - static not match', () {
      // given
      var route = new Route("/route/");

      // when
      var match = route.match("/other/");

      // then
      expect(match, isNull);
    });

    test('matching - static not match any tail', () {
      // given
      var route = new Route("/route/");

      // when
      var match = route.match("/route/subpath");

      // then
      expect(match, isNull);
    });

    test('matching - static match', () {
      // given
      var route = new Route("/route/");

      // when
      var match = route.match("/route/");

      // then
      expect(match, equals({}));
    });

    test('matching - one parameter match', () {
      // given
      var route = new Route("/route/{param}/");

      // when
      var match = route.match("/route/value/");

      // then
      expect(match, equals({"param" : "value"}));
    });

    test('matching - several parameter match', () {
      // given
      var route = new Route("/route/{param1}/name/{param2}/{param3}/");

      // when
      var match = route.match("/route/value1/name/value2/value3/");

      // then
      expect(match, equals({
        "param1" : "value1",
        "param2" : "value2",
        "param3" : "value3",
      }));
    });

    test('generation - two params', () {
      // given
      var route = new Route("/route/{param1}/{param2}/");

      // when
      var path = route.path({'param1': 'value1', 'param2': 'value2'});

      // then
      expect(path, equals('/route/value1/value2/'));
    });

    test('generation - not enough params', () {
      // given
      var route = new Route("/route/{param1}/{param2}/");

      // when & then
      expect(() => route.path({'param1': 'value1'}), throwsArgumentError);
    });

    test('escape variable values', () {
      // given
      var route = new Route("/route/{param}/");
      var params = {'param': '/\\!@#\$%^&*(){}|"\':;/.,-=?<>'};

      // when
      var path = route.path(params);

      // then
      expect(path, equals("/route/${Uri.encodeComponent(params['param'])}/"));
    });

    test('parse escaped variable values from url', () {
      // given
      var route = new Route("/route/{param1}/");
      var params = {'param1': '/\\!@#\$%^&*(){}|"\':;/.,-=?<>'};

      // when
      var params_there_and_back = route.match(route.path(params));

      // then
      expect(params, equals(params_there_and_back));
    });

    test('match any tail', () {
      // given
      var route = new Route("/any-tail/{param}/*");

      // when
      var match = route.match("/any-tail/value/something/anything");

      // then
      expect(match, equals({
        "param" : "value",
        "_tail" : "something/anything",
      }));
    });
  });

  group('Router', () {
    test('to path - static', () {
      //given
      Router router = new Router("", {'static' : new Route('/static/')});

      //when
      var path = router.routePath("static", {});

      //then
      expect(path, equals('/static/'));
    });

    test('register route', () {
      //given
      Router router = new Router("", {});
      router.registerRoute('static', new Route('/static/'));

      //when
      var path = router.routePath("static", {});

      //then
      expect(path, equals('/static/'));
    });

    test('to path - not existing', () {
      //given
      Router router = new Router("", {'static' : new Route('/static/')});

      //when & then
      expect(() => router.routePath("not-existing", {}), throwsArgumentError);
    });

    test('to path - one parameter', () {
      //given
      Router router = new Router("", {'one-param' : new Route('/{param}/')});

      //when
      var path = router.routePath("one-param", {"param" : "value"});

      //then
      expect(path, equals('/value/'));
    });

    test('to url', () {
      //given
      Router router = new Router("http://www.host.com", {'static' : new Route('/static/')});

      //when
      var url = router.routeUrl("static", {});

      //then
      expect(url, equals('http://www.host.com/static/'));
    });

    test('path matching - static', () {
      //given
      Router router = new Router("", {'static' : new Route('/static/')});

      //when
      var match = router.match("/static/");

      //then
      expect(match[0], equals("static"));
      expect(match[1], equals({}));
    });

    test('path matching - one parameter', () {
      //given
      Router router = new Router("", {'one-param' : new Route('/{param}/')});

      //when
      var match = router.match("/value/");

      //then
      expect(match[0], equals("one-param"));
      expect(match[1], equals({"param":"value"}));
    });

    test('path matching - undefined', () {
      //given
      Router router = new Router("", {'static' : new Route('/static/')});

      //when & then
      expect(router.match("/something-different/"), isNull);
    });
  });
}