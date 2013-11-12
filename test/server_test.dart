// Copyright (c) 2013, Peter Csiba. All rights reserved. Use of this source
// code is governed by a BSD-style license that can be found in the LICENSE
// file.

import 'package:unittest/unittest.dart';
import 'package:unittest/mock.dart';
import '../lib/server.dart';
import '../lib/router.dart';
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
  test ('distinguish between GET and POST', (){
    //given
    var controller = new StreamController<HttpRequest>();
    var req = new HttpRequestMock(Uri.parse('/dummy/url/'),method:'GET');

    var router = new MockRouter();
    router.when(callsTo('match')).alwaysReturn(['route_name', {}]);

    var navigator = new RequestNavigator(controller.stream, router);;
    navigator.registerHandler('route_name', 'GET', expectAsync1((req) {}, count:1));
    navigator.registerHandler('route_name', 'POST', expectAsync1((req) {}, count:0));

    //when
    controller.add(req);
  });


  test ('default handler', (){
    //given
    var controller = new StreamController<HttpRequest>();
    var req = new HttpRequestMock(Uri.parse('/dummy/url/'),method:'GET');

    var router = new MockRouter();

    var navigator = new RequestNavigator(controller.stream, router);;
    navigator.registerDefaultHandler(expectAsync1((req) {}, count:1));

    //when
    controller.add(req);
  });
}