// Copyright (c) 2013, Samuel Hapak, Peter Csiba. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.
//TODO consider spliting into test file by classes tested

import 'package:unittest/unittest.dart';
import '../lib/router.dart';
import 'package:unittest/mock.dart';
import 'package:clean_data/clean_data.dart';
import 'dart:async';

class HistoryMock extends Mock implements HashHistory {
  String url = null;
  void pushState(Object data, String title, [String url]){
    this.url = url;
  }
  void replaceState(Object data, String title, [String url]){
    this.url = url;
  }
}

// History class for async testing
class HistoryAsyncMock extends Mock implements HashHistory {
  String expected_title;
  String expected_url;

  HistoryAsyncMock(this.expected_title, this.expected_url);

  void pushState(Object data, String title, [String url]){
    expect(title, equals(this.expected_title));
    expect(title, equals(this.expected_url));
  }
  void replaceState(Object data, String title, [String url]){
    expect(title, equals(this.expected_title));
    expect(title, equals(this.expected_url));
  }
}

class ViewMock extends Mock implements View {
  var state = null;
  Data data = null;
  void load(Data data){
    this.state = #load;
    this.data = data;
  }
  void unload(){
    this.state = #unload;
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

    final pathStatic = "/just/static/one";
    final patternOneParameter = "/route/{one_parameter}/";

    final routeStatic = new Route(pathStatic);
    final routeOneParameter = new Route(patternOneParameter);

    final routeNameStatic = "static";
    final routeNameOneParameter = "one_parameter";

    final hostName = 'http://www.google.com';

    var router = new Router(hostName, {
      routeNameStatic: routeStatic,
      routeNameOneParameter: routeOneParameter
    });

    var history = new HistoryMock();
    var historyReplaceCalls = 0;
    var historyPushCalls = 0;

    ViewMock viewStatic = new ViewMock();
    ViewMock viewOneParameter = new ViewMock();

    PageNavigator pageNavigator = new PageNavigator(router, history);
    pageNavigator.registerView(routeNameStatic, viewStatic);
    pageNavigator.registerView(routeNameOneParameter, viewOneParameter);

    //when & test
    test('PageNavigator should be initialized with no active route', () {
      expect(
        () => pageNavigator.activePath,
        throwsArgumentError
      );
    });

    //first transition from null to static page
    test('PageNavigator navigate to static page', () {
      // given initialized navigator at null state
      var params = {};

      // when
      pageNavigator.navigate(routeNameStatic, params);

      // then ========
      expect(pageNavigator.activePath, equals(pathStatic));

      // page navigator state
      history.getLogs(callsTo("replaceState")).verify(happenedExactly(++historyReplaceCalls));

      // histoty state
      expect(history.url, equals(pathStatic));

      // view methods called correctly
      viewStatic.getLogs(callsTo("load")).verify(happenedOnce);
      expect(viewStatic.getLogs(callsTo('load')).first.args.first.toJson(), equals(params));

      viewStatic.getLogs(callsTo("unload")).verify(happenedExactly(0));
    });

    test('PageNavigator push state', () {
      //given active page is static page (one transition)

      //when
      pageNavigator.pushState();

      //then
      history.getLogs(callsTo("replaceState")).verify(happenedExactly(historyReplaceCalls));
      history.getLogs(callsTo("pushState")).verify(++historyPushCalls);
    });

    test('PageNavigator navigate to non existing site', () {
      expect(
          () => pageNavigator.navigate("non-existing-site", {}),
          throwsStateError
      );
    });

    test('PageNavigator navigate to one param page', () {
      //given active page is static page (one transition)
      var params = {'one_parameter': 'suchy_pes'};
      var pathOneParameter = routeOneParameter.path(params);

      //when
      pageNavigator.navigate(routeNameOneParameter, params);

      //then =========
      //  PageNavigator state
      expect(pageNavigator.activePath, equals(pathOneParameter));

      // history state
      history.getLogs(callsTo("replaceState")).verify(happenedExactly(++historyReplaceCalls));
      history.getLogs(callsTo("pushState")).verify(happenedExactly(historyPushCalls));
      expect(history.url, equals(pathOneParameter));

      //view methods called correctly
      viewOneParameter.getLogs(callsTo("load")).verify(happenedOnce);
      expect(viewOneParameter.getLogs(callsTo('load')).first.args.first.toJson(), equals(params));

      viewOneParameter.getLogs(callsTo("unload")).verify(happenedExactly(0));
    });

    test('PageNavigator update url when Data updated', () {
      //==given active page is one parameter page (two transitions)
      //Note: forget global navigator, history and views
      var paramsOld = {'one_parameter': 'bozi_pan'};
      var paramsNew = {'one_parameter': 'mega_motac'};
      var pathOld = routeOneParameter.path(paramsOld);
      var pathNew = routeOneParameter.path(paramsNew);

      var view = new ViewMock();
      var historyAsync = new HistoryAsyncMock(null, pathNew);
      var navigator = new PageNavigator(router, historyAsync);

      navigator.registerView(routeNameOneParameter, view);
      navigator.navigate(routeNameOneParameter, paramsOld);

      //check if set up is correct
      expect(navigator.activePath, equals(pathOld));
      expect(view.getLogs(callsTo('load')).first.args.first.toJson(), equals(paramsOld));

      //==when
      view.data[paramsNew.keys.first] = paramsNew.values.first;

      //==then
      //check if history is updated correctly
      new Timer(new Duration(milliseconds: 100), expectAsync0(historyAsync.replaceState));
    });

    test('PageNavigator navigate to same view with different params', () {
      //given
      Map paramsNew = {'one_parameter': 'trosku_pan'};
      var pathNew = routeOneParameter.path(paramsNew);

      //when
      pageNavigator.navigate(routeNameOneParameter, paramsNew);

      //then (should propagate the change in data to view)
      expect(pageNavigator.activePath, equals(pathNew));

      //view data state
      expect(viewOneParameter.data, isNot(null));
      expect(viewOneParameter.data.keys.first, equals(paramsNew.keys.first));
      expect(viewOneParameter.data.values.first, equals(paramsNew.values.first));
      //no more load/unload for view
      viewOneParameter.getLogs(callsTo("load")).verify(happenedExactly(1));
      viewOneParameter.getLogs(callsTo("unload")).verify(happenedExactly(0));

      //history state
      expect(history.url, equals(pathNew));
      history.getLogs(callsTo("replaceState")).verify(happenedExactly(++historyReplaceCalls));
    });
  });
}





