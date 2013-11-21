// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

//TODO comment new /* feature

library clean_router.common;

/**
 * Maps [Map] of variables to [String] Url component and vice versa.
 */
class Route {
  RegExp _matchExp;
  List<String> _variables = [];
  List _urlParts = [];
  bool _anyTail = false;

  /**
   * Constructs [Route] using [String] pattern.
   *
   * Pattern is divided to parts by slash '/' character. The slash must be the
   * very first character of the pattern. Each part can be either static or
   * placeholder. Static part can contain arbitrary number of [a-zA-Z0-9_-]
   * characters. Placeholder part consists of variable name enclosed in curly
   * braces. Variable name consists of any characters expect curly braces
   * with the first character being not an underscore.
   */

  Route(String pattern) {
    if (pattern.isEmpty || pattern[0] != '/') {
      throw new FormatException("Url pattern has to begin with '/' character.");
    }
    if(pattern[pattern.length - 1] == '*'){
      _anyTail = true;
      pattern = pattern.substring(0, pattern.length - 1);
    }

    if (pattern[pattern.length - 1] != '/') {
      throw new FormatException("Url pattern has to end with '/' or '/*' characters.");
    }

    RegExp exp = new RegExp(r"^(?:([\w-]*)|{([^_{}][^{}]*)})$");
    var matcherParts = new List();
    var parts = pattern.split('/');
    for (var part in parts) {
      var match = exp.firstMatch(part);
      if (match == null) {
        throw new FormatException(
            """Only alphanumeric characters, dash '-' and underscore '_'
             are allowed in the URL."""
        );
      }
      if (match.group(1) != null) {
        var group = match.group(1);
        matcherParts.add(group);
        _urlParts.add({'value': group, 'isVariable': false});
      } else {
        var group = match.group(2);
        matcherParts.add("([^/]*)");
        _variables.add(group);
        _urlParts.add({'value': group, 'isVariable': true});
      }
    }

    var tailRegExp = r"";
    if(_anyTail){
      tailRegExp = r"(.*)";
    }

    _matchExp = new RegExp(r"^" + matcherParts.join('/') + tailRegExp + r"$");
  }

  /**
   * Matches the [url] against the [Route] pattern and returns [Map] of matched.
   * This is the inverse function to [Route.path].
   */
  Map match(String url) {
    var match = _matchExp.firstMatch(url);

    // If the [url] does not match, returns [null].
    if (match == null) {
      return null;
    }

    // Decode [url] parameters and fill them into [Map].
    Map result = new Map();
    for (var i = 0; i < _variables.length; i++) {
      result[_variables[i]] = Uri.decodeComponent(match.group(i + 1));
    }

    //Matched url after prefix
    if(_anyTail){
      result["_tail"] = Uri.decodeComponent(match.group(_variables.length + 1));
    }

    return result;
  }

  /**
   * Constructs the [url] using the [Route] pattern and values in [variables].
   * This is theiInverse function to [Route.match].
   * Accepts both [Map] and [Data] as parameters.
   * All [variables] of [Route] must be provided.
   */
  String path(dynamic variables) {
    var parts = [];
    for (var part in this._urlParts) {
      var value = part['value'];
      if (part['isVariable']) {
        value = variables[value];
        if (value == null) {
          throw new ArgumentError("Missing value for ${part['value']}.");
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
  final Map<String, Route> _routes;
  String _host;

  Router(this._host, this._routes);

  /**
   * Registeres a [route] identified by [routeName] in [Router].
   * It is not allowed to override already registered routes.
   */
  void registerRoute(String routeName, Route route) {
    if(_routes.containsKey(routeName)) {
      throw new ArgumentError("Route name '$routeName' already in use in Route.");
    }
    _routes[routeName] = route;
  }

  /**
   * Returns path part of the url corresponding to the given [routeName] and
   * [parameters]. Accepts [Map] and [Data] as [parameters].
   */
  String routePath(String routeName, dynamic parameters) {
    var route = this._routes[routeName];
    if (route == null) {
      throw new ArgumentError('Router does not contain a route "$routeName".');
    }
    return this._routes[routeName].path(parameters);
  }

  /**
   * Returns the whole url corresponding to the given [routeName] and
   * [parameters]. Accepts both [Map] and [Data] as [parameters].
   */
  String routeUrl(String routeName, dynamic parameters) {
    return this._host + this.routePath(routeName, parameters);
  }

  /**
   * Returns the List [[routeName, matchedParameters]] matching the [url].
   */
  List match(String url) {
    for (var key in this._routes.keys) {
      var match = this._routes[key].match(url);
      if (match != null) {
        return [key, match];
      }
    }
    return null;
  }
}
