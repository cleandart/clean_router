// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library clean_router.server;

import 'package:unittest/unittest.dart';
import 'package:unittest/mock.dart';
import '../lib/server.dart';
import 'dart:async';
import 'dart:io';

class MockRouter extends Mock implements Router {}

class HttpRequestMock extends Mock implements HttpRequest {
  Uri uri;
  String method;
  HttpRequestMock(this.uri, {this.method});
}

void main() {
  group('(Server)', () {
    test ('match route ', (){
      // given
      var controller = new StreamController<HttpRequest>();
      var req = new HttpRequestMock(Uri.parse('/dummy/{param}/'));

      var router = new MockRouter();
      router.when(callsTo('match')).alwaysReturn(['route_name', {'param':'value'}]);

      var navigator = new RequestNavigator(controller.stream, router);

      // when
      controller.add(req);

      // then
      navigator.registerHandler('route_name', expectAsync2((req, param) {
        expect(req.uri, equals(Uri.parse('/dummy/{param}/')));
        expect(param, equals({'param':'value'}));
      }, count:1));
    });

    test ('default handler', (){
      // given
      var router = new Router("", {});
      router.addRoute("static", new Route("/static/"));

      var controller = new StreamController<HttpRequest>();
      var navigator = new RequestNavigator(controller.stream, router);
      var req = new HttpRequestMock(Uri.parse('/not-existing/'));

      // when
      controller.add(req);

      // then
      navigator.registerHandler("static", expectAsync2((req, param) {}, count:0));
      navigator.registerDefaultHandler(expectAsync2((req, param) {}, count:1));
    });
  });
}
