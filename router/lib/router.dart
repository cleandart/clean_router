// Copyright (c) 2013, Samuel Hapak. All rights reserved. Use of this source
// code is governed by a BSD-style license that can be found in the LICENSE
// file.

library vacuum.router;
import "dart:core";
import "dart:uri";
import "dart:html";
import 'package:web_ui/web_ui.dart';
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
  ObservableMap match(String url) {
    var match = this._matchExp.firstMatch(url);

    // If the [url] does not match, returns [null].
    if (match == null) {
      return null;
    }

    // Decode [url] parameters and fill them into [Map].
    ObservableMap result = new ObservableMap();
    for (var i = 0; i < this._variables.length; i++) {
      result[this._variables[i]] = decodeUriComponent(match.group(i+1));
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
      parts.add(encodeUriComponent(value));
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
class PageNavigator {
  final observe;
  final History history;
  final Router router;
  final Map<String, dynamic> views;
  final transitionHandler;
  var activeRoute;
  var activeWatchDisposer;

  PageNavigator(
    this.observe,
    this.history,
    this.router,
    this.views,
    this.transitionHandler
    );

  /**
   * Navigates to the given [url] and renders the page.
   *
   * This consits of the following steps:
   *
   * 1. Match the [url] against the [Router] [Route]s
   * 2. Matches the [Route] to the corresponding view
   * 3. Handles the transition from current view to the matched one
   * 4. Pushes new [url] to the [History]
   * 5. Starts monitoring [Route] parameters for changes and automatically
   *    updates the [url] with [History.replaceState].
   */
  void navigate(url, [withoutPush = false]) {
    var match = this.router.match(url);
    this.transitionHandler(
      this.views[activeRoute],
      this.views[match[0]],
      match[1]
    );
    this.activeRoute = match[0];
    if (!withoutPush) {
      this.history.pushState(null, '', url);
    }

    // Stop watching parameters of the previous view.
    if (this.activeWatchDisposer != null) {
      this.activeWatchDisposer();
    }

    // Automatically update the [url] if the parameters got changed.
    this.activeWatchDisposer = this.observe(match[1], (e) {
      this.history.replaceState(null, '',
        this.router.routePath(this.activeRoute, e.newValue)
      );
    });
  }

}

PageNavigator createNavigator(List rules,
  [transitionHandler = simpleTransition]) {
  var routes = {};
  var views = {};
  for (var rule in rules) {
    routes[rule[0]] = rule[1];
    views[rule[0]] = rule[2];
  }
  var router = new Router(window.location.host, routes);
  var navigator =  new PageNavigator(observe, window.history, router, views,
    transitionHandler);

  delegateOn(window, 'click', (el) => el is AnchorElement, (ev, el) {
    // Ignore anchors without href.
    if (el.href == null) {
      return;
    }
    // Ignore urls pointing outside of the web.
    if (el.host != window.location.host) {
      return;
    }
    navigator.navigate(el.pathname);
    ev.preventDefault();
  });

  window.onPopState.listen(
    (e) => navigator.navigate(window.location.pathname, true)
  );

  // Initialize routing with current url.
  navigator.navigate(window.location.pathname);

  return navigator;
}
