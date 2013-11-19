// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library clean_router.client_browser;

import "dart:html";
import 'client.dart';
export 'client.dart';

class HashHistory  {

  void pushState(Object data, String title, [String url]) {
    window.location.hash = '#' + url;
  }

  void replaceState(Object data, String title, [String url]) {
    window.location.hash = '#' + url;
  }
}


PageNavigator createPageNavigator(Router router){
  if (window.history.pushState && window.history.replaceState) {
    return new PageNavigator(router, window.history);
  }
  else {
    return new PageNavigator(router, new HashHistory());
  }
}
