// Copyright (c) 2013, Peter Csiba. All rights reserved. Use of this source
// code is governed by a BSD-style license that can be found in the LICENSE
// file.

//TODO How we should handle uri parameters?
//TODO HttpRequest.method (incorporate into route or solve with filters?)
//TODO Futures
//TODO Should be handler a class?

library vacuum.router;
import "dart:core";
import 'dart:io';
import 'dart:async';
import 'router.dart';

/**
 * [RequestNavigator] wires together [Route] matching, [Filter]ing of [HttpRequests]
 * and [Handler] calling. It manages url addresses and bind them handlers.
 */
class RequestNavigator {
  final Stream<HttpRequest> _incoming;
  final Router _router;
  final Map<String, StreamController<HttpRequest>> _streams = {};

  /**
   * Contains [Route], [Filter], [Stream] triples where [Stream] has at least one handler.
   */
  final List _filters = [];

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
  Stream<HttpRequest> registerHandler(String routeName, dynamic handler){
    if(routeName == 'default') {
      throw new ArgumentError("Route name should not be 'default'.");
    }
    if(_streams.containsKey(routeName)){
      throw new ArgumentError("Route name '$routeName' already in use in RequestNavigator.");
    }

    _streams[routeName] = _createStreamControllerWithHandler(handler);
    return _streams[routeName].stream;
  }

  /**
   * When [Router] matches nothing then [handler] will be called (through the returned [Stream]).
   */
  Stream<HttpRequest> registerDefaultHandler(dynamic handler){
    //TODO what should we do if overriding?
    _streams['default'] = _createStreamControllerWithHandler(handler);
    return _streams['default'].stream;
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
      return _navigateToRoute(req, routeInfo[0], routeInfo[1]);
    }
    else{
      return _navigateToRoute(req, 'default', {});
    }
  }

  Stream<HttpRequest> _navigateToRoute(HttpRequest req, String routeName, Map params){
    if(!_streams.containsKey(routeName)){
      throw new ArgumentError("Stream not found for '$routeName'");
    }

    var streamController = _streams[routeName];
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