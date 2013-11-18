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
  HttpResponseMock response = new HttpResponseMock();

  HttpRequestMock(this.uri, {this.method});
}

class HttpResponseMock extends Mock implements HttpResponse {
  int statusCode;
  var _onClose;

  Future close() {
    if (_onClose != null) {
      _onClose();
    }
    return new Future.value();
  }
}


void main() {
  group('(Server)', () {
    test ('match route', (){
      //given
      var controller = new StreamController<HttpRequest>();
      var req = new HttpRequestMock(Uri.parse('/dummy/url/'));

      var router = new MockRouter();
      router.when(callsTo('match')).alwaysReturn(['route_name', {}]);

      var navigator = new RequestNavigator(controller.stream, router);;
      navigator.registerHandler('route_name', expectAsync1((param) {}, count:1));

      //when
      controller.add(req);
    });

    test ('right parameters ', (){
      //given
      var controller = new StreamController<HttpRequest>();
      var req = new HttpRequestMock(Uri.parse('/dummy/{param}/'));

      var router = new MockRouter();
      router.when(callsTo('match')).alwaysReturn(['route_name', {'param':'value'}]);

      var navigator = new RequestNavigator(controller.stream, router);;
      navigator.registerHandler('route_name', expectAsync1((param) {
        expect(param, new isInstanceOf<RequestHandlerParameters>());
        expect(param.req.uri, equals(Uri.parse('/dummy/{param}/')));
        expect(param.url_params, equals({'param':'value'}));
      }, count:1));

      //when
      controller.add(req);
    });

    test ('default handler', (){
      //given
      var controller = new StreamController<HttpRequest>();
      var req = new HttpRequestMock(Uri.parse('/dummy/url/'));

      var router = new MockRouter();

      var navigator = new RequestNavigator(controller.stream, router);;
      navigator.registerDefaultHandler(expectAsync1((param) {}, count:1));

      //when
      controller.add(req);
    });
  });
}
