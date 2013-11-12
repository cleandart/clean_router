// Copyright (c) 2013, Peter Csiba. All rights reserved. Use of this source
// code is governed by a BSD-style license that can be found in the LICENSE
// file.

import 'package:unittest/unittest.dart';
import 'package:unittest/mock.dart';
import '../lib/server.dart';
import 'dart:async';
import 'dart:io';

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

}