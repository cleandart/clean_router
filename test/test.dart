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
    //given
    final routeStatic = new Route("/just/static/one");
    final routeOneParameter = new Route("/route/{one_parameter}/");
    final routeTwoVariables = new Route("/my-site/{var1}/{var2}/your-site/");

    //when & test
    test('Unsupported route format', () {
      expect(
        () => new Route("not-starting-with-backslash"),
        throwsFormatException
      );
      //TODO what should be the behaviour?
      /*
      expect(
        () => new Route("/not-ending-with-backslash"),
        throwsFormatException
      );*/
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

    test('Basic route matching', () {
      expect(
          routeTwoVariables.match("/my-site/"),
          isNull
      );
      expect(
        routeTwoVariables.match("/my-site/432/123/your-site/"),
        equals({'var1': '432', 'var2': '123'})
      );
      expect(
        routeTwoVariables.match("/my_site/123/321/your-site/"),
        isNull
      );
    });

    test('Map returned from route matching is Map', () {
      expect(
        routeTwoVariables.match('/my-site/432/123/your-site/'),
        new isInstanceOf<Map>()
      );
    });

    test('Basic route generation', () {
      expect(
          routeTwoVariables.path({'var1': 'Hodnota', 'var2': 'Zloba'}),
          equals('/my-site/Hodnota/Zloba/your-site/')
      );
      expect(
          () => routeTwoVariables.path({'var1': 'Value'}),
          throwsFormatException
      );
    });

    test('Url escape variable values', () {
      var params1 = {'var1': 'hello/dolly', 'var2': 'Ok'};
      var params2 = {'var1': 'hello darling', 'var2': 'Here/we/are'};

      expect(
        routeTwoVariables.match(routeTwoVariables.path(params1)),
        equals(params1)
      );
      expect(
        routeTwoVariables.match(routeTwoVariables.path(params2)),
        equals(params2)
      );
    });
  });

  group('Router', () {
    //given
    final pathStatic = "/just/static/one";
    final patternOneParameter = "/route/{one_parameter}/";
    final patternTwoVariables = "/my-site/{var1}/{var2}/your-site/";

    final routeStatic = new Route(pathStatic);
    final routeOneParameter = new Route(patternOneParameter);
    final routeTwoVariables = new Route(patternTwoVariables);

    final routeNameStatic = "static";
    final routeNameOneParameter = "one_parameter";
    final routeNameTwoVariables = "two_variables";

    final hostName = 'http://www.google.com';

    var router = new Router(hostName, {
      routeNameStatic: routeStatic,
      routeNameOneParameter: routeOneParameter,
      routeNameTwoVariables: routeTwoVariables
    });

    //when & test
    test('Router route to path', () {
      expect(
        router.routePath(routeNameStatic, {}),
        equals(pathStatic)
      );
      expect(
        router.routePath(routeNameTwoVariables, {'var1': 'value1', 'var2': 'value2'}),
        equals('/my-site/value1/value2/your-site/')
      );
      expect(
        router.routePath(routeNameOneParameter, {'one_parameter': 'some_value'}),
        equals('/route/some_value/')
      );
    });

    test('Router route to url', () {
      expect(
        router.routeUrl(routeNameStatic, {}),
        equals(hostName + pathStatic)
      );
      expect(
        router.routeUrl(routeNameTwoVariables, {'var1': 'value1', 'var2': 'value2'}),
        equals(hostName + '/my-site/value1/value2/your-site/')
      );
      expect(
        router.routeUrl(routeNameOneParameter, {'one_parameter': 'some_value'}),
        equals(hostName + '/route/some_value/')
      );
    });

    test('Router route with undefined route throws Error', () {
      expect(
        () => router.routePath('invalid-route', {}),
        throwsArgumentError
      );
    });

    test('Route matching', () {
      var matchStatic = router.match(pathStatic);
      var matchOneParameter = router.match('/route/some_value/');
      var matchTwoVariables = router.match('/my-site/value1/value2/your-site/');

      expect(
          matchStatic[0],
          equals(routeNameStatic)
      );
      expect(
          matchStatic[1],
          equals({})
      );

      expect(
          matchOneParameter[0],
          equals(routeNameOneParameter)
      );
      expect(
          matchOneParameter[1],
          equals({'one_parameter': 'some_value'})
      );

      expect(
          matchTwoVariables[0],
          equals(routeNameTwoVariables)
      );
      expect(
          matchTwoVariables[1],
          equals({'var1': 'value1', 'var2': 'value2'})
      );
    });

    test('Route matching undefined route throws Error', () {
      expect(
          () => router.match('/invalid-route'),
          throwsArgumentError
      );
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
      var route = new Route("/dummy/{param}");
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
        view.getLogs(callsTo('unload')).verify(happenedExactly(0));
      });

      //listening to replace state confirms calling replace state
      history.when(callsTo('replaceState')).alwaysCall((a, b, c) => checkReplaceCall());
    });

    test('PageNavigator navigate to same view with different params', () {
      //==given
      var route = new Route("/dummy/{param}");
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
      view.getLogs(callsTo("unload")).verify(happenedExactly(0));
    });
  });
}





