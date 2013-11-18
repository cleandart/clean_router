// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library clean_router.client;
import "dart:core";
import "dart:async";
import 'package:clean_data/clean_data.dart';
import 'common.dart';
export 'common.dart';

/**
 * [View] is responsible for manipulating data received from server to be used for HTML.
 * Methods of [View] are called when [PageNavigator] matches the corresponding route
 *   or when is navigated to different location.
 */
abstract class View {
  /**
   * Called when [PageNavigator] decides a new [View] should be used/displayed.
   * [View] should listen do [data] changes.
   * From the other side [PageNavigator] listens to each [data] change of [View].
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
 * [PageNavigator] wires together [History] management, [Route] matching and
 * [View] rendering. It manages url addresses and bind them to views.
 * It updates url (replaceState, pushState) if the url params are changed in the view.
 */
class PageNavigator {
  final Router _router;
  final dynamic _history;
  String _activeRouteName;
  Data _activeParameters;
  StreamSubscription _dataSubscription;
  final Map _views = {};
  View _activeView;
  View _defaultView;
  
  String activePath = null;
  
/**
 * Creates new [PageNavigator].
 */
  PageNavigator(this._router, this._history);

/**
 * Registeres a [view] for a particular [Route] identified by [route_name] in [Router].
 * It is not allowed to override already registered view.
 */
  void registerView(String routeName, View view) {
    if(_views.containsKey(routeName)) {
      throw new ArgumentError("Route name '$routeName' already in use in PageNavigator.");
    }
    _views[routeName] = view;
  }

/**
 * Registers a [View] which is called when router does not find any match.
 */
  void registerDefaultView(View view) {
    _defaultView = view;
  }

/**
 * Navigates the browser to the selected route with given [data].
 * Then a [View] is selected and [Data] passed via updates are communicated.
 * So when [View] changes [Data] then [PageNavigator] changes [History] url.
 * Vice versa when client navigates to active route only [Data] is updated
 * and [View.load] and [View.unload] is not called. Therefore [View] should
 * listen to [Data] changes.
 *
 * Use flag [pushState] to push the new url to browser history.
 */
  void navigate(String routeName, Map parameters, {bool pushState: false}) {
    //== prepare variables

    if(!_views.containsKey(routeName)) {
      throw new ArgumentError("View not found for '$routeName'");
    }

    if (_activeView != _views[routeName]) {
      _setActiveParameters(parameters);
      _handleViewTransition(_activeView, _views[routeName]);
    }
    else {
      _activeParameters.removeAll(_activeParameters.keys.toList());
      _activeParameters.addAll(parameters);
    }

    _activeView = _views[routeName];
    _activeRouteName = routeName;
    
    //== update history
    if (pushState) {
      this.pushState();
    }
    else {
      _updateHistoryState();
    }
  }


/**
 *  Navigates the browser to the selected Path using [navigate] function.
 */
  void navigateToPath(String path, {bool pushState: false}) {
    var routeInfo = _router.match(path);
    if(routeInfo != null) {
      navigate(routeInfo[0], routeInfo[1], pushState: pushState);
    }
    else {
      _setActiveParameters({});
      _handleViewTransition(_activeView, _defaultView);
      _activeView = _defaultView ;
      activePath = path;

      if (pushState) {
        this.pushState();
      }
      else {
        _updateHistoryState();
      }
    }
  }
  
  void _recalculateActivePath() {
    if(_activeView != _defaultView) {
      activePath = _router.routePath(_activeRouteName, _activeParameters);
    }
  }
  
  void _handleViewTransition(View oldView, View newView) {
    if (oldView != null) {
      oldView.unload();
    }
    newView.load(_activeParameters);
  }

  void _setActiveParameters(Map parameters) {
    if(_dataSubscription != null) {
      _dataSubscription.cancel();
    }
    var data = new Data.from(parameters);
    _activeParameters = data;
    _dataSubscription = _activeParameters.onChange.listen(
        (ChangeSet change) => _updateHistoryState());
  }

  void _updateHistoryState() {
    _recalculateActivePath();
    _history.replaceState(new Object(), "", activePath);
  }

/**
 * Pushes the current state.
 * Should be called from [View] when [View] considers it necessary after block of [Data] changes.
 * Note that [Data].onChange callback is called in PageNavigator
 *   it will only call [_history.replaceState] which will do no harm.
 */
  void pushState() {
    _recalculateActivePath();
    this._history.pushState(new Object(), "", activePath);
  }
}
