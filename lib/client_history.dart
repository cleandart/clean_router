// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library clean_router.client_history;

import "dart:html";

/**
 * Should have the closest approximation of [dart.dom.history] as possible for browsers not supporting [HTML5].
 * This is implemented via tokens after hashes in url which are allowed to change by browsers.
 *
 * See http://api.dartlang.org/docs/releases/latest/dart_html/History.html#pushState .
 */

abstract class History {
  void pushState(Object data, String title, [String url]);
  void replaceState(Object data, String title, [String url]);
}

class HistoryFactory {  
  History getHistory() {
    if (window.history.pushState && window.history.replaceState) {
      return new Html5History();
    }
    else {
      return new HashHistory();
    }
  }
}

class HashHistory implements History {

  void pushState(Object data, String title, [String url]) {
    window.location.hash = '#' + url;
  }

  void replaceState(Object data, String title, [String url]) {
    window.location.hash = '#' + url;
  }
}

class Html5History implements History {
  
  void pushState(Object data, String title, [String url]) {
    if(url != null) {
      window.history.pushState(data,title,url);
    }
    else {
      window.history.pushState(data,title);
    }
  }

  void replaceState(Object data, String title, [String url]) {
    if(url != null) {
      window.history.replaceState(data,title,url);
    }
    else {
      window.history.replaceState(data,title);
    }
  }
}

