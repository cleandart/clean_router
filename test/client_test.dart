// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library client_test;

import 'dart:async';
import 'package:unittest/unittest.dart';
import 'package:unittest/mock.dart';
import 'package:clean_data/clean_data.dart';
import '../lib/client.dart';

// Spy for View
class DummyView implements View {
  DataMap data = null;
  void load(DataMap data) {
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
  group('(PageNavigator)', () {

    //when & test
    test('should be initialized with no active route', () {
      // given

      // when
      var pageNavigator = new PageNavigator(new MockRouter(), null);

      // then
      expect(pageNavigator.activePath, isNull);
    });

    test('navigate to non existing site', () {
      var pageNavigator = new PageNavigator(null, null);
      expect(
          () => pageNavigator.navigate("non-existing-site", {}),
          throwsArgumentError
      );
    });

    //transition from null to static page
    test('navigate to static page', () {
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
      expect(args[1], new isInstanceOf<DataMap>());

      history.getLogs(callsTo('replaceState')).verify(happenedOnce);

      view.getLogs(callsTo('load')).verify(happenedOnce);
      expect(view.getLogs().first.args.first["_routeName"], equals("static"));
    });

    test('navigate to path.', () {
      // given
      var router = new MockRouter();
      var view = new MockView();
      router.when(callsTo('match')).alwaysReturn(["route", {'param': 'value'}]);
      router.when(callsTo('routePath')).alwaysReturn("/dummy/value/");
      var pageNavigator = new PageNavigator(router, new Mock());
      pageNavigator.registerView("route", view);

      // when
      pageNavigator.navigateToPath("/dummy/value/");

      // then
      expect(pageNavigator.activePath, equals("/dummy/value/"));

      router.getLogs(callsTo('match')).verify(happenedOnce);

      view.getLogs(callsTo('load')).verify(happenedOnce);
      expect(view.getLogs().first.args.first['param'], equals('value'));
      expect(view.getLogs().first.args.first['_routeName'], equals('route'));
    });

    test('re-navigation during view.load action used to cause troubles', () {
      //given
      var router = new MockRouter();
      router.when(callsTo("routePath", "routeA")).alwaysReturn("/route/a/");
      router.when(callsTo("routePath", "routeB")).alwaysReturn("/route/b/");
      var viewA = new MockView();
      var viewB = new SpyView();
      var pageNavigator = new PageNavigator(router, new Mock());
      pageNavigator.registerView("routeA", viewA);
      pageNavigator.registerView("routeB", viewB);
      viewA.when(callsTo('load')).thenCall(
        (data){
          pageNavigator.navigate("routeB", {});
        }
      );

      //when
      pageNavigator.navigate("routeA", {});

      //then
      expect(pageNavigator.activePath, equals("/route/b/"));

    });

    test('navigate to non existing path leads to invoking defaultView.', () {
      // given
      var router = new Router(null,{});
      var view = new MockView();

      var pageNavigator = new PageNavigator(router, new Mock());
      pageNavigator.registerDefaultView(view);

      // when
      pageNavigator.navigateToPath("/dummy/url/");

      // then
      expect(pageNavigator.activePath, equals("/dummy/url/"));
      view.getLogs(callsTo('load')).verify(happenedOnce);
    });

    test('push state', () {
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

    test('update url when Data updated', () {
      //given
      var route = new Route("/dummy/{param}/");
      var paramsOld = {'param': 'pipkos'};
      var paramsNew = {'param': 'fajne'};

      var view = new SpyView();
      var history = new Mock();

      var navigator = new PageNavigator(new Router("host", {"page" : route}), history);

      navigator.registerView("page", view);
      navigator.navigate("page", paramsOld);

      //when
      view._real.data["param"] = 'fajne';

      //then
      var checkReplaceCall = expectAsync0(() {
        expect(navigator.activePath, equals(route.path(paramsNew)));

        //only view.load was called at navigator.navigate
        view.getLogs(callsTo('load')).verify(happenedOnce);
        view.getLogs(callsTo('unload')).verify(neverHappened);
      });

      //listening to replace state confirms calling replace state
      history.when(callsTo('replaceState')).alwaysCall((a, b, c) => checkReplaceCall());
    });

    test('navigate to same view with different params', () {
      //given
      var route = new Route("/dummy/{param}/");
      var paramsOld = {'param': 'sad_kitty'};
      var paramsNew = {'param': 'happy_kitty'};
      var pathNew = route.path(paramsNew);

      var view = new SpyView();
      var history = new Mock();

      var navigator = new PageNavigator(new Router("host", {"page" : route}), history);

      navigator.registerView("page", view);
      navigator.navigate("page", paramsOld);

      //assume set up is correct (tested previously)

      //when
      navigator.navigate("page", paramsNew);

      //then (should propagate the change in data to view)
      return new Future.delayed(new Duration(milliseconds: 100), () {
        //pageNavigator state
        expect(navigator.activePath, equals(pathNew));

        //history state
        //3 for navigate(old) and navigate(new) and data.onChange
        history.getLogs(callsTo("replaceState")).verify(happenedExactly(3));
        expect(history.getLogs(callsTo('replaceState')).last.args[2], equals(pathNew));

        //view data state
        expect(view._real.data['param'], equals('happy_kitty'));
        expect(view._real.data['_routeName'], equals('page'));

        //no more load/unload for view
        view.getLogs(callsTo("load")).verify(happenedExactly(1));
        view.getLogs(callsTo("unload")).verify(neverHappened);
      });
    });

    test('checked unsuscribing data', () {
      //given
      var view = new DummyView();
      var params = {'param': 'happy_kitty'};
      var history = new Mock();
      var navigator = new PageNavigator(new MockRouter(), history);

      var calls = 0;
      var checkMaxTwo = () => guardAsync(() {
        history.getLogs(callsTo('replaceState')).verify(happenedAtMost(2));
      });

      history.when(callsTo('replaceState')).alwaysCall((a,b,[c]) => checkMaxTwo());

      //when
      navigator.registerView('first', view);
      navigator.registerView('second',new MockView());

      navigator.navigate('first',params);
      var data = view.data;
      navigator.navigate('second',{});

      data['param'] = 'vacuumcleaner';
    });

    test('navigate to same view with different routes', () {
      //given
      var catRoute = new Route("/cat/{param}/");
      var dogRoute = new Route("/dog/{param}/");
      var dogParams = {"param":"doggy"};
      var dogPath = dogRoute.path(dogParams);

      var view = new SpyView();
      var history = new Mock();

      var navigator = new PageNavigator(new Router("host", {
        "cat" : catRoute,
        "dog" : dogRoute})
      , history);

      navigator.registerView("cat", view);
      navigator.registerView("dog", view);
      navigator.navigate("cat", {"param":"kitty"});

      //when
      navigator.navigate("dog", dogParams);

      //then
      return new Future.delayed(new Duration(milliseconds: 100), (){
        expect(navigator.activePath, equals(dogPath));

        //history state
        //3 for navigate(old) and navigate(new) and data.onChange
        history.getLogs(callsTo("replaceState")).verify(happenedExactly(3));
        //last path is dogPath
        expect(history.getLogs(callsTo('replaceState')).last.args[2], equals(dogPath));

        //view data state
        expect(view._real.data['param'], equals('doggy'));
        expect(view._real.data['_routeName'], equals('dog'));
        //no more load/unload for view
        view.getLogs(callsTo("load")).verify(happenedExactly(1));
        view.getLogs(callsTo("unload")).verify(neverHappened);
      });
    });
  });
}




