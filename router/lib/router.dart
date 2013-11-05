// Copyright (c) 2013, Samuel Hapak. All rights reserved. Use of this source
// code is governed by a BSD-style license that can be found in the LICENSE
// file.

/* 
 *   TODO Consider if neccessary: Route: map -> clean_data.Data
 *   Timer.run()
 *   TOVIEW: clean_data.unit_test , GWT methodology 
 */

library vacuum.router;
import "dart:core";
import "dart:html";
import 'package:clean_data/clean_data.dart'; 

//TODO consider moving to a separate file
/**
 * [View] is responsible for manipulating data received from server to be used for HTML.
 * Methods of [View] are called when [PageNavigator] matches the corresponding route or is navigated to different location. 
 */
abstract class View{
  /**
   * Called when [PageNavigator] decides a new [View] should be used/displayed. 
   * [View] should listen do data changes. [PageNavigator] listens to each data change of [View].  
   * See [PageNavigator.navigate] for more. 
   * 
   * @param data Data parsed from url. 
   */
  void load(Data data);
  
  /**
   * Called when [PageNavigator] decides this [View] is no more necessary/to be displayed.
   * Here the implementation should release all unnecessary resources.  
   */
  void unload(); 
}

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
   * Matches the [url] against the [Route] pattern and returns [Map] of matched.
   * Inverse function to [Route.path]. 
   * 
   * @param url Url to be matched.  
   * @returns Parameters or [null] if the Route does not match.
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
   * Inverse function to [Route.match]. 
   * 
   * @param variables Variables to be substitued. 
   * @returns Constructed url. 
   * @throws FormatException If some variable was not provided in [variables].  
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
 * [PageNavigator] wires together [History] management, [Route] matching and
 * view rendering.
 * 
 */
class PageNavigator {
  Router _router; 
  dynamic _history; 
  String _activeRouteName;
  Data _activeParameters; 
  
  Map _views;
  
/**
 * Create a new [PageNavigator] for client to allow him navigate through the site. 
 * Responsibility: Manage url addresses and bind them to views. It updates url (replaceState, pushState) if the url params are changed in the view. 
 *  
 * @param _router For matching route names to routes and parameters. 
 * @param _history Should have pushState and replaceState with semantics as dart.dom.history. See [HashHistory] for more. 
 */
  PageNavigator(this._router, this._history);
  
/**
 * Navigates the browser to the selected route with given data. A [View] is selected and [Data] passed. 
 * When [View] changes [Data] then [PageNavigator] calls history.replaceState with a new url. 
 * From the other side when [PageNavigator.navigate] is called to an actual [View] the [Data] is updated and therefore [Vew] sould listen to [Data] changes. 
 * 
 * @param name Name of the route to be navigated to. 
 * @param data Parameter values.
 * @param pushState If the new url (state) should be pushed to browser history. 
 */
  void navigate(String name, Map data, [bool pushState]){
    /* TODO 
    *        //inlcude discussion, that data holder should listen to changes    
    *        if same name no load and unload
    *        data.clear
      *        data.addAll
        *      pushState -> pushes actual state, don't block anything so on notify callback the replaceState will be called
        */ 
  }  
}

//TODO not sure if panko
/**
 * Should have the closest approximation of [dart.dom.history] as possible for browsers not supporting [HTML5].
 * This is implemented via tokens after hashes in url which are allowed to change by browsers. 
 * 
 * See http://api.dartlang.org/docs/releases/latest/dart_html/History.html#pushState .
 */
class HashHistory {
  /**
   * Navigates to url.  
   */
  void pushState(Object data, String title, [String url]){
    window.location.hash = '#' + url;
  }

  /**
   * Navigates to url. 
   */
  void replaceState(Object data, String title, [String url]){
    window.location.hash = '#' + url;
  }
}









