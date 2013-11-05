// Copyright (c) 2013, Samuel Hapak. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/unittest.dart';
import 'lib/router.dart';
import 'package:unittest/mock.dart';
import 'package:clean_data/clean_data.dart'; 
import 'dart:async';

class HistoryMock extends Mock implements HashHistory {
  var url = null; 
  var type = null; 
  void pushState(Object data, String title, [String url]){
    this.url = url;
    this.type = "push";
  }
  void replaceState(Object data, String title, [String url]){
    this.url = url; 
    this.type = "replace";
  }
}

class ViewMock extends Mock implements View{
  var state = null; 
  Data data = null; 
  void load(Data data){
    this.state = "load";
    this.data = data; 
  }
  void unload(){
    this.state = "unload";
  }
}

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
  
  HistoryMock history = new HistoryMock();
  var historyReplaceCalls = 0; 
  ViewMock view2 = new ViewMock(); 
  ViewMock view3 = new ViewMock();
  Map views = {
               "my-site" : null, 
               "static"  : view2, 
               "one-param" : view3
  };
  
  test('PageNavigator constructed', (){
    expect(new PageNavigator(router, history, views), isNot(null));
  });
  
  PageNavigator pageNavigator = new PageNavigator(router, history, views);
  
  test('PageNavigator navigate to static page', () {
    pageNavigator.navigate("static", {}); 
    
    String route2Path = route2.path({}); 
    
    expect(pageNavigator.getActivePath(), equals(route2Path));
    
    history.getLogs(callsTo("replaceState")).verify(happenedExactly(++historyReplaceCalls));
    expect(history.url, equals(route2Path)); 
    
    view2.getLogs(callsTo("load")).verify(happenedExactly(1));
    view2.getLogs(callsTo("unload")).verify(happenedExactly(1));
    expect(view2.data, isNot(null));
    expect(view2.data.isEmpty, true); 
  });

  test('PageNavigator push state', () {
    pageNavigator.pushState();
    history.getLogs(callsTo("pushState")).verify(happenedExactly(1));
  });

  test('PageNavigator navigate to null view', () {
    expect(
        () => pageNavigator.navigate("my-site", {}),
        throwsNullThrownError
    ); 
  });

  test('PageNavigator navigate to one param page', () {
      Map params = {'one_parameter': 'suchy_pes'}; 
      pageNavigator.navigate('one-param', params); 
      
      String route3Path = route3.path(params); 
      
      expect(pageNavigator.getActivePath(), equals(route3Path));
      
      history.getLogs(callsTo("replaceState")).verify(happenedExactly(++historyReplaceCalls));
      expect(history.url, equals(route3Path)); 

      view2.getLogs(callsTo("load")).verify(happenedExactly(1));
      view2.getLogs(callsTo("unload")).verify(happenedExactly(1));
      
      view3.getLogs(callsTo("load")).verify(happenedExactly(1));
      view3.getLogs(callsTo("load")).verify(happenedExactly(0));
      expect(view3.data, isNot(null));
      expect(view3.data.keys.first, equals(params.keys.first));
      expect(view3.data.values.first, equals(params.values.first)); 
  });
  
  test('PageNavigator update url when Data updated', () {
    Map newParams = {'one_parameter': 'bozi_pan'}; 
    String route3Path = route3.path(newParams); 
    
    view3.data[newParams.keys.first] = newParams.values.first;
    
    //TODO how to do it? 
    //asynchronous check
    Timer.run(() { 
      expect(pageNavigator.getActivePath(), equals(route3Path));
      history.getLogs(callsTo("replaceState")).verify(happenedExactly(++historyReplaceCalls));
      expect(history.url, equals(route3Path)); 
    });
  });

  test('PageNavigator navigate to same view with different params', () {
    Map newParams = {'one_parameter': 'mega_motac'}; 
    String route3Path = route3.path(newParams); 
    
    pageNavigator.navigate('one-param', newParams); 
    expect(pageNavigator.getActivePath(), equals(route3Path));
    
    expect(view3.data, isNot(null));
    expect(view3.data.keys.first, equals(newParams.keys.first));
    expect(view3.data.values.first, equals(newParams.values.first)); 
    
    history.getLogs(callsTo("replaceState")).verify(happenedExactly(++historyReplaceCalls));
    expect(history.url, equals(route3Path)); 
    
    view3.getLogs(callsTo("load")).verify(happenedExactly(1));
    view3.getLogs(callsTo("unload")).verify(happenedExactly(0));
  });
}





