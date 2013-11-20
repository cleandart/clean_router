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


PageNavigator createPageNavigator() {
  var location = window.location;
  var urlPrefix = "${location.protocol}//${location.host}";
  var router = new Router(urlPrefix, {});

  var history = History.supportsState ? window.history : new HashHistory();
  var navigator = new PageNavigator(router, history);

  window.document.body.onClick.matches('a[href]').listen((Event event) {
    var a = event.matchingTarget;
    var href = event.matchingTarget.href;

    if (a.protocol == window.location.protocol && a.host == window.location.host) {
      event.preventDefault();
      navigator.navigateToPath(a.pathname, pushState: true);
    }
  });

  if (History.supportsState) {
    window.onPopState.listen((PopStateEvent event) {
      navigator.navigateToPath(window.location.pathname);
    });

  } else {
    window.onHashChange.listen((event) {
      navigator.navigateToPath(window.location.hash.substring(1));
    });
  }

  return navigator;
}
