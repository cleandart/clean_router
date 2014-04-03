// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

//TODO comment new /* feature

library clean_router.common;

const PARAM_TAIL = '_tail';

/**
 * Maps [Map] of variables to [String] Url component and vice versa.
 */
class Route {
  RegExp _matchExp;
  String _absolutePart = '';
  List<String> _variables = [];
  List _urlParts = [];
  bool _anyTail = false;

  get isAbsolute => _absolutePart.isNotEmpty;

  /**
   * Constructs [Route] using [String] pattern.
   *
   * Url is dividid into absolute and patter part.
   * Pattern is divided to parts by slash '/' character. The slash must be the
   * very first character of the pattern. Each part can be either static or
   * placeholder. Static part can contain arbitrary number of [a-zA-Z0-9_-]
   * characters. Placeholder part consists of variable name enclosed in curly
   * braces. Variable name consists of any characters expect curly braces
   * with the first character being not an underscore.
   */

  Route(String url) {
    String pattern;
    if(url.startsWith(new RegExp(r'^(ht|f)tp(s?)://'))) {
      int endOfAbsolutePart = url.indexOf('/', url.indexOf('://') + 3);
      if(endOfAbsolutePart == -1) {
        throw new FormatException('Absolute Url pattern has to have pattern part');
      }
      _absolutePart = url.substring(0, endOfAbsolutePart);
      pattern = url.substring(endOfAbsolutePart);
    }
    else {
      pattern = url;
    }

    if (pattern.isEmpty || pattern[0] != '/') {
      throw new FormatException("Url pattern has to begin with '/' character.");
    }
    if(pattern[pattern.length - 1] == '*'){
      _anyTail = true;
      pattern = pattern.substring(0, pattern.length - 1);
    }

    var staticPart = r"([^{}]+)";
    var matcherPart = r"(\{[a-zA-Z0-9-][_a-zA-Z0-9-]*\})";
    var customMatcherPart = r"(\{[a-zA-Z0-9-][_a-zA-Z0-9-]*:[^{}]+\})";
    RegExp exp = new RegExp(r"^(" + staticPart + r"|" + matcherPart + r"|" + customMatcherPart + r")*$");
    var match = exp.firstMatch(pattern);
    if (match == null) {
      throw new FormatException(
          """Only alphanumeric characters, dash '-' and underscore '_'
           are allowed in the URL."""
      );
    }

    bool hasCustomMatchPart = false;

    RegExp matcherPartExp = new RegExp(matcherPart);
    var matches = matcherPartExp.allMatches(pattern);

    if (matches.isEmpty) {
      matcherPartExp = new RegExp(customMatcherPart);
      matches = matcherPartExp.allMatches(pattern);
      hasCustomMatchPart = true;
    }

    var matcherParts = new List();
    var start = 0;
    addStatic(_static) {
      if (_static != '') {
        matcherParts.add(_static.replaceAllMapped(
                    new RegExp(r"[.?*+^$[\]\\(){}|-]"), (c) => "\\${c.group(0)}")
                    );
        _urlParts.add({'value': _static, 'isVariable': false});
      }
    }

    for (var match in matches) {
      addStatic(pattern.substring(start,  match.start));
      start = match.end;

      var variableName;

      if (hasCustomMatchPart) {
        int colonIndex = pattern.indexOf(":", match.start);
        variableName = pattern.substring(match.start + 1, colonIndex);
        var customMatcher = pattern.substring(colonIndex + 1, match.end - 1);
        matcherParts.add("($customMatcher)");
      } else {
        variableName = pattern.substring(match.start + 1, match.end - 1);
        matcherParts.add("([^/]+)");
      }

      _variables.add(variableName);
      _urlParts.add({'value': variableName, 'isVariable': true});

    }
    addStatic(pattern.substring(start));


    var tailRegExp = r"";
    if(_anyTail){
      tailRegExp = r"(.*)";
    }

    _matchExp = new RegExp(r"^" + _absolutePart + matcherParts.join('') + tailRegExp + r"$");
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
      result[PARAM_TAIL] = Uri.decodeComponent(match.group(_variables.length + 1));
    }

    return result;
  }

  /**
   * Constructs the [url] using the [Route] pattern and values in [variables].
   * This is theiInverse function to [Route.match].
   * Accepts both [Map] as parameters.
   * All [args] of [Route] must be provided.
   */
  String path(Map args) {
    var parts = [];
    for (var part in this._urlParts) {
      var value = part['value'];
      if (part['isVariable']) {
        value = args[value];
        if (value == null) {
          throw new ArgumentError("Missing value for ${part['value']}.");
        }
        value = Uri.encodeComponent(value);
      }
      parts.add(value);
    }
    if (_anyTail) {
      parts.add(args[PARAM_TAIL]);
    }
    return _absolutePart + parts.join('');
  }
}

/**
 * When navigating to default view it will get
 * parameters {PARAM_ROUTE_NAME : PARAM_ROUTE_NAME_DEFAULT}
 */
const PARAM_ROUTE_NAME = "_routeName";

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
  void addRoute(String routeName, Route route) {
    if(_routes.containsKey(routeName)) {
      throw new ArgumentError("Route name '$routeName' already in use in Route.");
    }
    if(routeName == PARAM_ROUTE_NAME) {
      throw new ArgumentError("Route name cannot be '$PARAM_ROUTE_NAME' in PageNavigator.");
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
    String path = this.routePath(routeName, parameters);
    return this._routes[routeName].isAbsolute ? path : this._host + path;
  }

  /**
   * Returns the List [[routeName, matchedParameters]] matching the [url].
   */
  List match(String url) {
    for (var key in this._routes.keys) {
      var match = this._routes[key].match(url);
      if (match != null) {
        match[PARAM_ROUTE_NAME] = key;
        return [key, match];
      }
    }
    return null;
  }
}
