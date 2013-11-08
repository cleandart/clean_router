// Copyright (c) 2013, Samuel Hapak, Peter Csiba. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.
//TODO consider spliting into test file by classes tested

import 'package:unittest/unittest.dart';
import '../lib/router.dart';
import 'package:unittest/mock.dart';
import 'package:clean_data/clean_data.dart';

// Spy for View
class DummyView implements View {
  Data data = null;
  void load(Data data) {
    this.data = data;
  }
  void unload() {
    this.data = null;
  }
}

class MockRouter extends Mock implements Router {}
class MockView extends Mock implements DummyView {}

class SpyView extends Mock implements View {
  DummyView _real;

  SpyView() {
    _real = new DummyView();
    when(callsTo('load')).alwaysCall(_real.load);
    when(callsTo('unload')).alwaysCall(_real.unload);
  }
}

void main() {
  group('Route', () {
    test('Unsupported route format', () {
      expect(() => new Route(""), throwsFormatException);
      expect(() => new Route("not-starting-with-slash/"),throwsFormatException);
      expect(() => new Route("/not-ending-with-slash"),  throwsFormatException);
      expect(() => new Route("/#some-chars-not-allowed"),throwsFormatException);
      expect(() => new Route("/?some-chars-not-allowed"),throwsFormatException);
      expect(() => new Route("/!some-chars-not-allowed"),throwsFormatException);
      expect(() => new Route("/.some-chars-not-allowed"),throwsFormatException);
      expect(() => new Route("/{not_closed/"),           throwsFormatException);
      expect(() => new Route("/not_open}/"),             throwsFormatException);
      expect(() => new Route("/{{more-brackets}/"),      throwsFormatException);
      expect(() => new Route("/{more-brackets}}/"),      throwsFormatException);
    });

    test('Supported route format', () {
      expect(new Route("/"), isNot(isException));
      expect(new Route("//"), isNot(isException));
      expect(new Route("////////////////////////"), isNot(isException));
      expect(new Route("/{anything-here4!@#\$%^&*()\\\n}/"), isNot(isException));
    });

    test('Matching - static not match', () {
      // given
      var route = new Route("/route/");

      // when
      var match = route.match("/other/");

      // then
      expect(match, isNull);
    });

    test('Matching - static match', () {
      // given
      var route = new Route("/route/");

      // when
      var match = route.match("/route/");

      // then
      expect(match, equals({}));
    });

    test('Matching - one parameter match', () {
      // given
      var route = new Route("/route/{param}/");

      // when
      var match = route.match("/route/value/");

      // then
      expect(match, equals({"param" : "value"}));
    });

    test('Matching - several parameter match', () {
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

    test('Generation - two params', () {
      // given
      var route = new Route("/route/{param1}/{param2}/");

      // when
      var path = route.path({'param1': 'value1', 'param2': 'value2'});

      // then
      expect(path, equals('/route/value1/value2/'));
    });

    test('Generation - not enough params', () {
      // given
      var route = new Route("/route/{param1}/{param2}/");

      // when & then
      expect(() => route.path({'param1': 'value1'}), throwsArgumentError);
    });

    test('Escape variable values', () {
      // given
      var route = new Route("/route/{param}/");
      var params = {'param': '/\\!@#\$%^&*(){}|"\':;/.,-=?<>'};

      // when
      var path = route.path(params);

      // then
      expect(path, equals("/route/${Uri.encodeComponent(params['param'])}/"));
    });

    test('Parse esacaped variable values from url', () {
      // given
      var route = new Route("/route/{param1}/");
      var params = {'param1': '/\\!@#\$%^&*(){}|"\':;/.,-=?<>'};

      // when
      var params_there_and_back = route.match(route.path(params));

      // then
      expect(params, equals(params_there_and_back));
    });
  });

  group('Router', () {
    test('Route to path - static', () {
      //given
      Router router = new Router("", {'static' : new Route('/static/')});

      //when
      var path = router.routePath("static", {});

      //then
      expect(path, equals('/static/'));
    });

    test('Route to path - not existing', () {
      //given
      Router router = new Router("", {'static' : new Route('/static/')});

      //when & then
      expect(() => router.routePath("not-existing", {}), throwsArgumentError);
    });

    test('Route to path - one parameter', () {
      //given
      Router router = new Router("", {'one-param' : new Route('/{param}/')});

      //when
      var path = router.routePath("one-param", {"param" : "value"});

      //then
      expect(path, equals('/value/'));
    });

    test('Route to url', () {
      //given
      Router router = new Router("http://www.host.com", {'static' : new Route('/static/')});

      //when
      var url = router.routeUrl("static", {});

      //then
      expect(url, equals('http://www.host.com/static/'));
    });

    test('Path matching - static', () {
      //given
      Router router = new Router("", {'static' : new Route('/static/')});

      //when
      var match = router.match("/static/");

      //then
      expect(match[0], equals("static"));
      expect(match[1], equals({}));
    });

    test('Path matching - one parameter', () {
      //given
      Router router = new Router("", {'one-param' : new Route('/{param}/')});

      //when
      var match = router.match("/value/");

      //then
      expect(match[0], equals("one-param"));
      expect(match[1], equals({"param":"value"}));
    });

    test('Path matching - undefined', () {
      //given
      Router router = new Router("", {'static' : new Route('/static/')});

      //when & then
      expect(() => router.match("/something-different/"), throwsArgumentError);
    });
  });

/**
 * Page navigator is tested as simulating simple client actions chronologically.
 */
  group('PageNavigator', () {

    //when & test
    test('PageNavigator should be initialized with no active route', () {
      // given

      // when
      var pageNavigator = new PageNavigator(new MockRouter(), new Mock());

      // then
      expect(pageNavigator.activePath, isNull);
    });

    test('PageNavigator navigate to non existing site', () {
      var pageNavigator = new PageNavigator(new MockRouter(), new MockView());
      expect(
          () => pageNavigator.navigate("non-existing-site", {}),
          throwsArgumentError
      );
    });

    //transition from null to static page
    test('PageNavigator navigate to static page', () {
      // given
      var router = new MockRouter();
      var view = new MockView();
      var history = new Mock();
      router.when(callsTo('routePath')).alwaysReturn("/dummy/url/");
      var pageNavigator = new PageNavigator(router, history);
      pageNavigator.registerView("static", view);

      // when
      pageNavigator.navigate("static", {});

      // then
      expect(pageNavigator.activePath, equals("/dummy/url/"));

      router.getLogs(callsTo('routePath')).verify(happenedAtLeastOnce);
      var args = router.getLogs(callsTo('routePath')).first.args;
      expect(args[0], equals('static'));
      expect(args[1], equals({}));

      history.getLogs(callsTo('replaceState')).verify(happenedOnce);

      view.getLogs(callsTo('load')).verify(happenedOnce);
      expect(view.getLogs().first.args.first.isEmpty, isTrue);
    });
    
    test('PageNavigator navigate to path.', () {
      // given
      var router = new MockRouter();
      var view = new MockView();
      router.when(callsTo('match')).alwaysReturn(["route", {'arg': '1'}]);
      router.when(callsTo('routePath')).alwaysReturn("/dummy/url/");
      var pageNavigator = new PageNavigator(router, new Mock());
      pageNavigator.registerView("route", view);

      // when
      pageNavigator.navigateToPath("/dummy/url/");

      // then
      expect(pageNavigator.activePath, equals("/dummy/url/"));

      router.getLogs(callsTo('match')).verify(happenedOnce);

      view.getLogs(callsTo('load')).verify(happenedOnce);
      expect(view.getLogs().first.args.first.containsKey('arg'),isTrue);
    });
    
    test('PageNavigator navigate to non existing path.', () {
      // given
      var router = new Router(null,{});
      var view = new MockView();

      var pageNavigator = new PageNavigator(router, new Mock());
      pageNavigator.registerDefaultView(view);

      // when
      pageNavigator.navigateToPath("/dummy/url/");

      // then
      expect(pageNavigator.activePath, equals(null));

      view.getLogs(callsTo('load')).verify(happenedOnce);
    });
    
    test('PageNavigator push state', () {
      //given
      var router = new MockRouter();
      var view = new MockView();
      var history = new Mock();
      router.when(callsTo('routePath')).alwaysReturn("/dummy/url/");

      var pageNavigator = new PageNavigator(router, history);
      pageNavigator.registerView("static", view);
      pageNavigator.navigate("static", {});

      //when
      pageNavigator.pushState();

      //then
      history.getLogs(callsTo('replaceState')).verify(happenedOnce);
      history.getLogs(callsTo('pushState')).verify(happenedOnce);
    });

    test('PageNavigator navigate to one param page', () {
      // given
      var router = new MockRouter();
      var view = new MockView();
      router.when(callsTo('routePath')).alwaysReturn("/dummy/parameter_value/");
      var pageNavigator = new PageNavigator(router, new Mock());
      pageNavigator.registerView("one_param", view);

      // when
      pageNavigator.navigate("one_param", {"param":"parameter_value"});

      // then
      expect(pageNavigator.activePath, equals("/dummy/parameter_value/"));
    });

    test('PageNavigator update url when Data updated', () {
      //==given
      var route = new Route("/dummy/{param}/");
      var paramsOld = {'param': 'pipkos'};
      var paramsNew = {'param': 'fajne'};

      var view = new SpyView();
      var history = new Mock();

      var navigator = new PageNavigator(new Router("host", {"page" : route}), history);

      navigator.registerView("page", view);
      navigator.navigate("page", paramsOld);

      //==when
      view._real.data["param"] = 'fajne';

      //==then
      var checkReplaceCall = expectAsync0(() {
        expect(navigator.activePath, equals(route.path(paramsNew)));

        //only view.load was called at navigator.navigate
        view.getLogs(callsTo('load')).verify(happenedOnce);
        view.getLogs(callsTo('unload')).verify(neverHappened);
      });

      //listening to replace state confirms calling replace state
      history.when(callsTo('replaceState')).alwaysCall((a, b, c) => checkReplaceCall());
    });

    test('PageNavigator navigate to same view with different params', () {
      //==given
      var route = new Route("/dummy/{param}/");
      var paramsOld = {'param': 'bozi_pan'};
      var paramsNew = {'param': 'mega_motac'};
      var pathNew = route.path(paramsNew);

      var view = new SpyView();
      var history = new Mock();

      var navigator = new PageNavigator(new Router("host", {"page" : route}), history);

      navigator.registerView("page", view);
      navigator.navigate("page", paramsOld);

      //assume set up is correct (tested previously)

      //==when
      navigator.navigate("page", paramsNew);

      //==then (should propagate the change in data to view)
      expect(navigator.activePath, equals(pathNew));

      //history state
      //2 for navigate(old) and navigate(new)
      history.getLogs(callsTo("replaceState")).verify(happenedExactly(2));
      expect(history.getLogs(callsTo('replaceState')).last.args[2], equals(pathNew));

      //view data state
      expect(view._real.data.keys.first, equals(paramsNew.keys.first));
      expect(view._real.data.values.first, equals(paramsNew.values.first));
      //no more load/unload for view
      view.getLogs(callsTo("load")).verify(happenedExactly(1));
      view.getLogs(callsTo("unload")).verify(neverHappened);
    });
  });
}





