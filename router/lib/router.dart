// Copyright (c) 2013, Samuel Hapak, Peter Csiba. All rights reserved. Use of this source
// code is governed by a BSD-style license that can be found in the LICENSE
// file.

library vacuum.router;
import "dart:core";
import "dart:html";
import 'package:clean_data/clean_data.dart';

//TODO consider moving to a separate file
//TODO test behaviour of view?
/**
 * [View] is responsible for manipulating data received from server to be used for HTML.
 * Methods of [View] are called when [PageNavigator] matches the corresponding route
 *   or when is navigated to different location.
 */
abstract class View{
  /**
   * Called when [PageNavigator] decides a new [View] should be used/displayed.
   * [View] should listen do data changes. [PageNavigator] listens to each data change of [View].
   * See [PageNavigator.navigate] for more.
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
   * Inverse function to [Route.match]. Returns constructed url.
   * Accepts [Map] and [Data] as parameters.
   * Throws [FormatException] if some variable was not provided in [variables].
   */
  String path(dynamic variables) {
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
   * [parameters]. Accepts [Map] and [Data] as [parameters].
   */
  String routePath(String routeName, dynamic parameters) {
    var route = this.routes[routeName];
    if (route == null) {
      throw new ArgumentError('Router does not contain a route "$routeName".');
    }
    return this.routes[routeName].path(parameters);
  }

  /**
   * Returns the whole url corresponding to the given [routeName] and
   * [parameters]. Accepts [Map] and [Data] as [parameters].
   */
  String routeUrl(String routeName, dynamic parameters) {
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
 * [View] rendering.
 *
 */
class PageNavigator {
  Router _router;
  dynamic _history;
  String _activeRouteName;
  Data _activeParameters;
  Map _views;

  String get activePath => this._router.routePath(this._activeRouteName, this._activeParameters);

/**
 * Create a new [PageNavigator] for client to allow him navigate through the site.
 * Responsibility: Manage url addresses and bind them to views. It updates url (replaceState, pushState) if the url params are changed in the view.
 * Parameter [_router] for matching route names to routes and parameters.
 * Parameter [_history] should have pushState and replaceState with semantics as dart.dom.history. See [HashHistory] for more.
 * Parameter [_views] is map of ROUTE_NAME : View to render.
 * Throws [ArgumentError] when at least one of the arguments is null.
 */
  PageNavigator(this._router, this._history){
    if(this._router == null){
      throw new ArgumentError("Cannot construct PageNavigator as router is null.");
    }
    if(this._history == null){
      throw new ArgumentError("Cannot construct PageNavigator as history is null.");
    }
  }

/**
 * Registeres a [View] for a particular [Route].
 * Throws [ArgumentError] if trying to overwrite an already registered [route_name].
 */
  void registerView(String route_name, View view){
    //TODO consider only warning
    if(this._views.containsKey(route_name)){
      throw new ArgumentError("Route name '$route_name' already in use in PageNavigator.");
    }
    this._views[route_name] = view;
  }

/**
 * Navigates the browser to the selected route with given [data]. A [View] is selected and [Data] passed.
 * When [View] changes [Data] then [PageNavigator] calls history.replaceState with a new url.
 * From the other side when [PageNavigator.navigate] is called to an actual [View]
 *   the [Data] is updated and therefore [Vew] sould listen to [Data] changes.
 * Parameter [name] of the route to be navigated to.
 * Parameter [data] route parameter values.
 * Flag [pushState] if the new url (state) should be pushed to browser history.
 * Throws [StateError] when trying to navigate to a null [View].
 * Throws [ArgumentError] when no such route exists.
 */
  void navigate(String name, Map data, {bool pushState}){
    if(this._views[name] == null){
      throw new StateError("View not found for '$name'");
    }
    /* TODO
    *        //include discussion, that data holder should listen to changes
    *        if same name no load and unload
    *        data.clear
      *        data.addAll
        *      pushState -> pushes actual state, don't block anything so on notify callback the replaceState will be called
        */
  }

/**
 * Pushes the current state.
 * Should be called from [View] when [View] considers it necessary after block of [Data] changes.
 * Note that [Data].onChange callback is called in PageNavigator
 *   it will only call [_history.replaceState] which will do no harm.
 */
  void pushState(){
    this._history.pushState(new Object(), "", this.activePath);
  }
}

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






