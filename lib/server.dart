// Copyright (c) 2013, Peter Csiba. All rights reserved. Use of this source
// code is governed by a BSD-style license that can be found in the LICENSE
// file.

//TODO HttpRequest.method
//TODO Futures

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
  final Map<String, Stream<HttpRequest>> _streams = {};

  /**
   * Contains [Route], [Filter], [Stream] triples where [Stream] has at least one handler.
   */
  final List _filters = [];

  Stream<HttpRequest> _default;

  /**
   * Creates new RequestNavigator
   */
  RequestNavigator(this._incoming, this._router);

  /**
   * Registers [Handler] for a [Route] and adds listener to the stream which
   * is also returned.
   */
  Stream<HttpRequest> registerHandler(String routeName, dynamic handler){
    //TODO
    return null;
  }

  /**
   * When [Router] matches nothing then [handler] will be called (through the returned [Stream]).
   */
  Stream<HttpRequest> registerDefaultHandler(dynamic handler){
    //TODO
    return null;
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
    //TODO
    return null;
  }

}


abstract class Filter{
  /**
   * Should work as a WHERE condition.
   */
  bool filter(HttpRequest req);
}