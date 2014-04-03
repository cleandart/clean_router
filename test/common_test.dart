// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library commont_test;

import 'package:unittest/unittest.dart';
import 'package:clean_router/common.dart';

int main(){
  group('(Route)', () {
    test('unsupported format', () {
      expect(() => new Route(""), throwsFormatException);
      expect(() => new Route("not-starting-with-slash/"),throwsFormatException);
      expect(() => new Route("/onlyalphanumeric/{#}/"), throwsFormatException);
      expect(() => new Route("/{not_closed/"),           throwsFormatException);
      expect(() => new Route("/not_open}/"),             throwsFormatException);
      expect(() => new Route("/{{more-brackets}/"),      throwsFormatException);
      expect(() => new Route("/{more-brackets}}/"),      throwsFormatException);
      expect(() => new Route("/{_cannot-start-with-underscore}/"), throwsFormatException);
      expect(() => new Route("http://does-not-have-pattern-part.com"), throwsFormatException);
      expect(() => new Route("http://not_ending-with-slash.com/{#invalidpatternpart}/"), throwsFormatException);
      expect(() => new Route("else://example/{param}/not-ending-with-slash"), throwsFormatException);
      expect(() => new Route("/{variableMatcherCantContainBrackets:{}}/"), throwsFormatException);
    });

    test('supported format', () {
      expect(new Route("/"), isNot(isException));
      expect(new Route("//"), isNot(isException));
      expect(new Route("/anything-here4!@#\$%^&*()\\\n/"),isNot(isException));
      expect(new Route("/index.html/"), isNot(isException));
      expect(new Route("/index.html"), isNot(isException));
      expect(new Route("////////////////////////"), isNot(isException));
      expect(new Route("/anytail/*"), isNot(isException));
      expect(new Route("/{-__underscores-ok-if-not-first}/*"), isNot(isException));
      expect(new Route("http://absolutePath/"), isNot(isException));
      expect(new Route("http://absolutePath/index.html"), isNot(isException));
      expect(new Route("http://example//////////"), isNot(isException));
      expect(new Route("/not-ending-with-slash"),  isNot(isException));
      expect(new Route("http://example/{param}/not-ending-with-slash"),  isNot(isException));
      expect(new Route("https://example/{param}/not-ending-with-slash"),  isNot(isException));
      expect(new Route("ftp://example/{param}/not-ending-with-slash"),  isNot(isException));
      expect(new Route("/{variableMatcher:.*}/"), isNot(isException));

    });

    group('(relative)', () {
      test('matching - static not match', () {
        // given
        var route = new Route("/route/");

        // when
        var match = route.match("/other/");

        // then
        expect(route.isAbsolute, isFalse);
        expect(match, isNull);
      });

      test('matching - static not match any tail', () {
        // given
        var route = new Route("/route/");

        // when
        var match = route.match("/route/subpath");

        // then
        expect(route.isAbsolute, isFalse);
        expect(match, isNull);
      });

      test('matching - static match', () {
        // given
        var route = new Route("/route/index.html");

        // when
        var match = route.match("/route/index.html");

        // then
        expect(route.isAbsolute, isFalse);
        expect(match, equals({}));
      });

      test('matching - one parameter match', () {
        // given
        var route = new Route("/route/{param}/");

        // when
        var match = route.match("/route/value/");

        // then
        expect(route.isAbsolute, isFalse);
        expect(match, equals({"param" : "value"}));
      });

      test('matching - several parameter match', () {
        // given
        var route = new Route("/route/{param1}/name/{param2}/{param3}/img.jpg");

        // when
        var match = route.match("/route/value1/name/value2/value3/img.jpg");

        // then
        expect(route.isAbsolute, isFalse);
        expect(match, equals({
          "param1" : "value1",
          "param2" : "value2",
          "param3" : "value3",
        }));
      });

      test('matching filename and its extension', () {
        // given
        var route = new Route('/some-file/{filename}.{ext}');

        // when
        var match = route.match("/some-file/report.doc");

        // then
        expect(route.isAbsolute, isFalse);
        expect(match, equals({
          'filename': 'report',
          'ext': 'doc',
        }));
      });

      test('matching - one parameter with custom regular expression', () {
        // given
        var route = new Route("/route/{param:[a-z0-9]+}/");

        // when
        var match = route.match("/route/hello15/");

        // then
        expect(route.isAbsolute, isFalse);
        expect(match, equals({"param" : "hello15"}));

      });

      test('matching - one parameter with custom regular expression and more url parts', () {
        // given
        var route = new Route("/route/{param:\\d+}/article/");

        // when
        var match = route.match("/route/15/article/");

        // then
        expect(route.isAbsolute, isFalse);
        expect(match, equals({"param" : "15"}));

      });

      test('matching - several parameters with custom regular expression', () {
        // given
        var route = new Route("/route/{month:\\d+}/{day:[1-9][0-9]*}/");

        // when
        var match = route.match("/route/02/30/");

        // then
        expect(route.isAbsolute, isFalse);
        expect(match, equals({
            "month" : "02",
            "day" : "30"
        }));

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

    group('(absolute)', () {
      test('matching - absolute url', () {
        // given
        var route = new Route("http://new.example.com/");
        var route2 = new Route("http://new.example.com/");
        // when
        var match = route.match("http://new.example.com/");
        var match2 = route2.match("http://example/");
        // then
        expect(match, equals({}));
        expect(match2, isNull);
        expect(route.isAbsolute, isTrue);
      });

      test('matching - static not match', () {
        // given
        var route = new Route("http://example.com/route/");

        // when
        var match = route.match("http://example.com/other/");

        // then
        expect(route.isAbsolute, isTrue);
        expect(match, isNull);
      });

      test('matching - static not match any tail', () {
        // given
        var route = new Route("http://example.com/route/");

        // when
        var match = route.match("http://example.com/route/subpath");

        // then
        expect(route.isAbsolute, isTrue);
        expect(match, isNull);
      });

      test('matching - static match', () {
        // given
        var route = new Route("http://example.com/route/");

        // when
        var match = route.match("http://example.com/route/");

        // then
        expect(route.isAbsolute, isTrue);
        expect(match, equals({}));
      });

      test('matching - one parameter match', () {
        // given
        var route = new Route("http://example.com/route/{param}/source.dart");

        // when
        var match = route.match("http://example.com/route/value/source.dart");

        // then
        expect(route.isAbsolute, isTrue);
        expect(match, equals({"param" : "value"}));
      });

      test('matching - several parameter match', () {
        // given
        var route = new Route("http://example.com/route/{param1}/name/{param2}/{param3}/");

        // when
        var match = route.match("http://example.com/route/value1/name/value2/value3/");

        // then
        expect(route.isAbsolute, isTrue);
        expect(match, equals({
          "param1" : "value1",
          "param2" : "value2",
          "param3" : "value3",
        }));
      });

      test('match any tail', () {
        // given
        var route = new Route("http://example/any-tail/{param}/*");

        // when
        var match = route.match("http://example/any-tail/value/something/anything");

        // then
        expect(match, equals({
          "param" : "value",
          "_tail" : "something/anything",
        }));
      });
    });

    group('generation relative', () {
      test('- two params', () {
        // given
        var route = new Route("/route/{param1}/{param2}/source.dart");

        // when
        var path = route.path({'param1': 'value1', 'param2': 'value2'});

        // then
        expect(path, equals('/route/value1/value2/source.dart'));
      });

      test('- not enough params', () {
        // given
        var route = new Route("/route/{param1}/{param2}/");

        // when & then
        expect(() => route.path({'param1': 'value1'}), throwsArgumentError);
      });


      test('- with tail', () {
        //given
        var route = new Route('/tail/*');

        //when
        var path = route.path({'_tail': 'anytail'});

        //then
        expect(path, equals('/tail/anytail'));
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

      test('generate filename and its extension', () {
        // given
        var route = new Route('/some-file/{filename}.{ext}');
        var params = {'filename': 'financial-report', 'ext': 'doc'};

        // when
        var path = route.path(params);

        // then
        expect(path, equals("/some-file/financial-report.doc"));
      });
    });

    group('generation absolute', () {
      test('- two params', () {
        // given
        var route = new Route("http://example/route/{param1}/{param2}/");

        // when
        var path = route.path({'param1': 'value1', 'param2': 'value2'});

        // then
        expect(path, equals('http://example/route/value1/value2/'));
      });

      test('- not enough params', () {
        // given
        var route = new Route("http://example/route/{param1}/{param2}/");

        // when & then
        expect(() => route.path({'param1': 'value1'}), throwsArgumentError);
      });


      test('- with tail', () {
        //given
        var route = new Route('http://example/tail/*');

        //when
        var path = route.path({'_tail': 'anytail'});

        //then
        expect(path, equals('http://example/tail/anytail'));
      });

      test('escape variable values', () {
        // given
        var route = new Route("http://example/route/{param}/");
        var params = {'param': '/\\!@#\$%^&*(){}|"\':;/.,-=?<>'};

        // when
        var path = route.path(params);

        // then
        expect(path, equals("http://example/route/${Uri.encodeComponent(params['param'])}/"));
      });
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

    test('match all relative', () {
      // given
      var route = new Route("/*");

      // when
      var match = route.match("/any-tail/value/something/anything");
      var match2 = route.match("http://example/any-tail/value/something/anything");
      // then
      expect(match, equals({
        "_tail" : "any-tail/value/something/anything",
      }));
      expect(match2, isNull);
    });

    test('match all with prefix', () {
      // given
      var route = new Route("/index*");

      // when
      var match = route.match("/index.html");
      var match2 = route.match("/index.php");
      var match3 = route.match("/main.php");
      // then
      expect(match, equals({
        "_tail" : ".html",
      }));
      expect(match2, equals({
        "_tail" : ".php",
      }));
      expect(match3, isNull);
    });
  });

  group('(Router)', () {
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
      router.addRoute('static', new Route('http://example/static/'));

      //when
      var path = router.routePath("static", {});

      //then
      expect(path, equals('http://example/static/'));
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

    test('to absolute url', () {
      //given
      Router router = new Router("http://www.host.com",
          {'static' : new Route('http://example/static/')});

      //when
      var url = router.routeUrl("static", {});

      //then
      expect(url, equals('http://example/static/'));
    });

    test('path matching - static', () {
      //given
      Router router = new Router("", {'static' : new Route('/static/')});

      //when
      var match = router.match("/static/");

      //then
      expect(match[0], equals("static"));
      expect(match[1], equals({PARAM_ROUTE_NAME: 'static'}));
    });

    test('path matching - one parameter', () {
      //given
      Router router = new Router("", {'one-param' : new Route('/{param}/')});

      //when
      var match = router.match("/value/");

      //then
      expect(match[0], equals("one-param"));
      expect(match[1], equals({"param":"value", PARAM_ROUTE_NAME: 'one-param'}));
    });

    test('path matching - order of routes matter', () {
      //given
      Router router = new Router("", {});
      router.addRoute('static', new Route('/static/'));
      router.addRoute('all_other', new Route('/*'));

      //when
      var match = router.match("/static/");

      //then
      expect(match[0], equals("static"));
      expect(match[1], equals({PARAM_ROUTE_NAME: 'static'}));
    });

    test('path matching - undefined', () {
      //given
      Router router = new Router("", {'static' : new Route('/static/')});

      //when & then
      expect(router.match("/something-different/"), isNull);
    });
  });
}