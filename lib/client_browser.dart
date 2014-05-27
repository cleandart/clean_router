// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library clean_router.client_browser;

import "dart:html";
import 'client.dart';
import 'dart:async';
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
  Timer.run(() {
      var path = window.location.pathname;
      path += path.endsWith('/') ? '' : '/';
      navigator.navigateToPath(path, pushState: false);
  });

  (window.document as HtmlDocument).body.onClick.matches('a[href]').listen((Event event) {
    var a = event.matchingTarget as AnchorElement;
    var href = a.href;

    if (a.protocol == window.location.protocol && a.host == window.location.host) {
      event.preventDefault();
      navigator.navigateToPath(a.pathname, pushState: true);
    }
  });

  if (History.supportsState) {
    window.onPopState.listen((PopStateEvent event) {
      navigator.navigateToPath(window.location.pathname, pushState: false);
    });
  } else {
    window.onHashChange.listen((event) {
      navigator.navigateToPath(window.location.hash.substring(1), pushState: false);
    });
  }

  return navigator;
}

/**
 * Creates and sends form with [postData] to [url].
 *
 * This method inserts new form into the [window.document.body] and sends
 * it to the [url] by calling [FormElement.submit()] method.
 */
redirectPost(url, Map postData) {
  FormElement form = new FormElement();
  form.action = url;
  form.method = "POST";
  postData.forEach((k,v) {
    InputElement input = new InputElement();
    input.type = 'hidden';
    input.value = v;
    input.name = k;
    form.append(input);
  });
  (window.document as HtmlDocument).body.append(form);
  form.submit();
}
