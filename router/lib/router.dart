// Copyright (c) 2013, Samuel Hapak. All rights reserved. Use of this source
// code is governed by a BSD-style license that can be found in the LICENSE
// file.

library vacuum.router;
import "dart:core";
import "dart:html";
import 'package:delegate/delegate.dart';

/**
 * Maps [Map] of variables to [String] Url component and vice versa.
 */
class Route {
  RegExp _matchExp;
  List<String> _variables = [];
  List _urlParts = [];

  /**
   * Constructs [Route] using [String] pattern.
   *
   * Pattern is divided to parts by slash '/' character. The slash must be the
   * very first character of the pattern. Each part can be either static or
   * placeholder. Static part can contain arbitrary number of [a-zA-Z0-9_-]
   * characters. Placeholder part consists of variable name enclosed in curly
   * braces. Variable name consists of [a-zA-Z0-9_] characters, with the first
   * character being a letter.
   */
  Route(pattern) {
    if (pattern[0] != '/') {
      throw new FormatException("Url pattern has to begin with '/' character.");
    }

    final RegExp exp = new RegExp(r"^(?:([\w-]*)|{([a-zA-Z][\w]*)})$");
    var matcherParts = new List();
    var parts = pattern.split('/');
    for (var part in parts) {
      var match = exp.firstMatch(part);
      if (match == null) {
        throw new FormatException(
            "Only alphanumeric characters, dash '-' and underscore '_'"
            " are allowed in the URL."
            );
      }
      if (match.group(1) != null) {
        var group = match.group(1);
        matcherParts.add(group);
        _urlParts.add({'value': group, 'isVariable': false});
      } else {
        var group = match.group(2);
        matcherParts.add("([^/]*)");
        this._variables.add(group);
        this._urlParts.add({'value': group, 'isVariable': true});
      }
    }

    this._matchExp = new RegExp(r"^" + matcherParts.join('/') + r"$");
  }
  /**
   * Matches the [url] against the [Route] pattern and returns [Map] of matched
   * parameters or [null] if the Route does not match.
   */
  Map match(String url) {
    var match = this._matchExp.firstMatch(url);

    // If the [url] does not match, returns [null].
    if (match == null) {
      return null;
    }

    // Decode [url] parameters and fill them into [Map].
    Map result = new Map();
    for (var i = 0; i < this._variables.length; i++) {
      result[this._variables[i]] = Uri.decodeComponent(match.group(i+1));
    }

    return result;
  }

  /**
   * Constructs the [url] using the [Route] pattern and values in [variables].
   */
  String path(Map variables) {
    var parts = [];
    for (var part in this._urlParts) {
      var value = part['value'];
      if (part['isVariable']) {
        value = variables[value];
        if (value == null) {
          throw new FormatException("Missing value for ${part['value']}.");
        }
      }
      parts.add(Uri.encodeComponent(value));
    }
    return parts.join('/');
  }
}

/**
 * [Router] consists of multiple named [Route]s and provides methods for
 * translating [Route]s to url/path and vice versa.
 */
class Router {
  final Map<String, Route> routes;
  String host;

  Router(this.host, this.routes);

  /**
   * Returns path part of the url corresponding to the given [routeName] and
   * [parameters].
   */
  String routePath(String routeName, Map parameters) {
    var route = this.routes[routeName];
    if (route == null) {
      throw new ArgumentError('Router does not contain a route "$routeName".');
    }
    return this.routes[routeName].path(parameters);
  }

  /**
   * Returns the whole url corresponding to the given [routeName] and
   * [parameters].
   */
  String routeUrl(String routeName, Map parameters) {
    return this.host + this.routePath(routeName, parameters);
  }

  /**
   * Returns the List [[routeName, matchedParameters]] matching the [url].
   */
  List match(String url) {
    for (var key in this.routes.keys) {
      var match = this.routes[key].match(url);
      if (match != null) {
        return [key, match];
      }
    }
    throw new ArgumentError('No route matches url "$url".');
  }
}

/**
 * Simple transition handler. Calls [unload] method on the [oldView] and the
 * [load] method with [parameters] on the [newView].
 */
void simpleTransition(oldView, newView, parameters) {
  // If this is the first time the page is loaded, [oldView] can be null, then
  // there is nothing to unload.
  if (oldView != null) {
    oldView.unload();
  }
  newView.load(parameters);
}

/**
 * [PageNavigator] wires together [History] management, [Route] matching and
 * view rendering.
 */
abstract class PageNavigator {
  final Router _router;
  final Map<String, dynamic> _views;
  final _transitionHandler;
  var _activeRoute;

  PageNavigator(
    this._router,
    this._views,
    this._transitionHandler
    );

  /**
   * Navigates to the given url.
   * Subclasses uses different approach based on HTML5 History support  
   */
  void navigate(url, [withoutPush = false]);
  
  /**
   * Changes view for given [url] and renders the page.
   *
   * This consits of the following steps:
   *
   * 1. Match the [url] against the [Router] [Route]s
   * 2. Matches the [Route] to the corresponding view
   * 3. Handles the transition from current view to the matched one
   */
  void _changeView(url, [withoutPush = false]) {
    var match = this._router.match(url);
    this._transitionHandler(
      this._views[_activeRoute],
      this._views[match[0]],
      match[1]
    );
    this._activeRoute = match[0];     
  }
}

class HistoryNavigator extends PageNavigator{
  
  final History _history;
  
  HistoryNavigator(this._history, router, views, transitionHandler) 
      : super(router, views, transitionHandler);
  
  /**
   * Navigates with HTML5 State API
   * 1. Pushes new [url] to the [History] if  [withoutPush] is false
   * 2.  Replaces new [url] if [withoutPush] is true
   */
  void navigate(url, [withoutPush = false]){
    _changeView(url);
    if (!withoutPush) {
      this._history.pushState(null, '', url);
    } else {
      this._history.replaceState(null, '', url);
    }
  }
}


class HashNavigator extends PageNavigator{
  
  HashNavigator(router, views, transitionHandler) 
  : super(router, views, transitionHandler);
  
  /**
   * Navigates with hash in url.
   *
   * Url is added behind #
   */
  void navigate(url, [withoutPush = false]){
    _changeView(url);  
    var activeUrl = window.location.href;
    if (activeUrl.indexOf('#') > 0) {
      window.location.href = activeUrl.substring(0, activeUrl.indexOf('#') + 1) + url;
    } else {
      window.location.href += '#' + url;
    }
  }
}

/**
 * PageNavigator factory
 * 
 * Creates HistoryNavigator instance if browser supports HTML5 State API, 
 * otherwise creates HashNavigator instance.
 */
PageNavigator createNavigator(List rules,
  [transitionHandler = simpleTransition]) {
  var routes = {};
  var views = {};
  for (var rule in rules) {
    routes[rule[0]] = rule[1];
    views[rule[0]] = rule[2];
  }
  var router = new Router(window.location.host, routes);
  var navigator = null;
  
  if (History.supportsState) {
    navigator =  new HistoryNavigator(window.history, router, views, transitionHandler);
  } else {
    navigator = new HashNavigator(router, views, transitionHandler);
  }
  
  delegateOn(document, 'click', (el) => el is AnchorElement, (ev, el) {
    // Ignore anchors without href.
    if (el.href == null) {
      return;
    }
    
    if (el.host == "") {
      if (!el.href.contains(window.location.host)) {
        return;
      }
    } else if (el.host != window.location.host) {
        return;
    }
    
    //IE9 ignores '/' in a.href
    var pathname = el.pathname;
    if (pathname[0] != '/') {
      pathname = '/' + pathname;
    } 
    
    navigator.navigate(pathname);
    ev.preventDefault();
  });

  window.onPopState.listen(
    (e) => navigator.navigate(window.location.pathname, true)
  );

  if (navigator is HashNavigator) {
    window.onHashChange.listen(
        (e) => navigator.navigate(window.location.hash.substring(1))
    );
  }
  
  return navigator;
}
