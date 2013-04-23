// Copyright (c) 2013, Samuel Hapak. All rights reserved. Use of this source
// code is governed by a BSD-style license that can be found in the LICENSE
// file.

library vacuum.router;
import "dart:core";
import "dart:uri";

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

class Router {
  final Map<String, Route> routes;
  String host;
  String activeRoute;

  Router(this.host, this.routes);

  String routePath(String routeName, Map variables) {
    var route = this.routes[routeName];
    if (route == null) {
      throw new ArgumentError('Router does not contain a route "$routeName".');
    }
    return this.routes[routeName].path(variables);
  }

  String routeUrl(String routeName, Map variables) {
    return this.host + this.routePath(routeName, variables);
  }

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
