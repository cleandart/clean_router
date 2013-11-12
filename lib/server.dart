// Copyright (c) 2013, Peter Csiba. All rights reserved. Use of this source
// code is governed by a BSD-style license that can be found in the LICENSE
// file.

//TODO Should we match HttpRequest with not set method?
//TODO How we should handle uri parameters?
//TODO   (sub of previous) should handler be an abstract class / interface?
//TODO Futures

library vacuum.router;
import "dart:core";
import 'dart:io';
import 'dart:async';
import 'dart:collection';
import 'common.dart';
export 'common.dart';

class _ServerRoute implements Comparable{
  String routeName;
  String method;

  _ServerRoute(this.routeName, this.method);

  int compareTo(_ServerRoute other) => (this.routeName != other.routeName) ?
      this.routeName.compareTo(other.routeName) : this.method.compareTo(other.method);

  bool operator ==(_ServerRoute other) => (this.routeName == other.routeName &&
      this.method == other.method);

  String toString() => routeName + ":" + method;
}

/**
 * [RequestNavigator] wires together [Route] matching, [Filter]ing of [HttpRequests]
 * and [Handler] calling. It manages url addresses and bind them handlers.
 */
class RequestNavigator {
  final Stream<HttpRequest> _incoming;
  final Router _router;
  final Map<_ServerRoute, StreamController<HttpRequest>> _streams
      = new SplayTreeMap<_ServerRoute, StreamController<HttpRequest>>();

  /**
   * Contains [Route], [Filter], [Stream] triples where [Stream] has at least one handler.
   */
  final List _filters = [];

  final _ServerRoute _defaultServerRouteId = new _ServerRoute('default', '');

  /**
   * Creates new RequestNavigator listening on [_incoming].
   */
  RequestNavigator(this._incoming, this._router){
    this._incoming.listen(navigate);
  }

  StreamController _createStreamControllerWithHandler(dynamic handler){
    StreamController<HttpRequest> streamController = new StreamController<HttpRequest>();
    streamController.stream.listen(handler);
    return streamController;
  }

  /**
   * Registers [Handler] for a [Route] and adds listener to the stream which
   * is also returned.
   */
  Stream<HttpRequest> registerHandler(String routeName, String method, dynamic handler){
    if(routeName == 'default') {
      throw new ArgumentError("Route name should not be 'default'.");
    }

    var serverRoute = new _ServerRoute(routeName, method);
    if(_streams.containsKey(serverRoute)){
      throw new ArgumentError("Route name '$serverRoute' already in use in RequestNavigator.");
    }

    _streams[serverRoute] = _createStreamControllerWithHandler(handler);
    return _streams[serverRoute].stream;
  }

  /**
   * When [Router] matches nothing then [handler] will be called (through the returned [Stream]).
   */
  Stream<HttpRequest> registerDefaultHandler(dynamic handler){
    //TODO what should we do if overriding?
    _streams[_defaultServerRouteId] = _createStreamControllerWithHandler(handler);
    return _streams[_defaultServerRouteId].stream;
  }

  /**
   * If incoming [HttpRequest] matches [route] then [filter] is called.
   * If the [filter] returns true then registered handler will be called
   * (through [Stream]). Otherwise [noPassedHandler] will be called (through the
   * returned [Stream]).
   */
  Stream<HttpRequest> registerFilter(Route route, Filter filter, dynamic notPassedHandler){
    //TODO
    return null;
  }

  /**
   * [HttpRequest.uri.path] is matched agains [Router],
   * whole [HttpRequest] is filtered through [Filter] and if passes all then
   * [HttpRequest] is inserted to the correspondig [Stream].
   */
  Stream<HttpRequest> navigate(HttpRequest req){
    var routeInfo = _router.match(req.uri.path);
    if(routeInfo != null){
      return _navigateToServerRoute(req, new _ServerRoute(routeInfo[0], req.method)
        , routeInfo[1]);
    }
    else{
      return _navigateToServerRoute(req, _defaultServerRouteId, {});
    }
  }

  Stream<HttpRequest> _navigateToServerRoute(HttpRequest req,
      _ServerRoute serverRoute, Map params){

    if(!_streams.containsKey(serverRoute)){
      throw new ArgumentError("Stream not found for '$serverRoute'");
    }

    var streamController = _streams[serverRoute];
    streamController.add(req);
    return streamController.stream;
  }
}


abstract class Filter{
  /**
   * Should work as a WHERE condition.
   */
  bool filter(HttpRequest req);
}

