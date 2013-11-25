// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library clean_router.server;

//TODO Filters

import "dart:core";
import 'dart:io';
import 'dart:async';
import 'common.dart';
export 'common.dart';

class RequestHandlerParameters{
  HttpRequest req;
  Map<String, String> url_params;

  RequestHandlerParameters(this.req, this.url_params);
}

/**
 * [RequestNavigator] wires together [Route] matching, [Filter]ing of
 * [HttpRequest]s and [Handler] calling. It manages url addresses and bind them
 * handlers.
 */
class RequestNavigator {
  final Stream<HttpRequest> _incoming;
  final Router _router;

  /**
   * Maps route names to [Stream]
   */
  final Map<String, StreamController<RequestHandlerParameters>> _streams = {};

  /**
   * If no route is matched.
   */
  StreamController<RequestHandlerParameters> _defaultStreamController = null;

  /**
   * Creates new RequestNavigator listening on [_incoming] and routing via
   * [_router].
   */
  RequestNavigator(this._incoming, this._router){
    this._incoming.listen(processHttpRequest);
  }

  StreamController _createStreamControllerWithHandler(dynamic handler){
    var streamController = new StreamController<RequestHandlerParameters>();
    streamController.stream.listen((p) => handler(p.req, p.url_params));
    return streamController;
  }

  /**
   * Registers [Handler] for a [Route] and adds listener to the stream which is
   * also returned.
   */
  void registerHandler(String routeName, dynamic handler){
    if(_streams.containsKey(routeName)){
      throw new ArgumentError("""Cannot register handler as route name
'$routeName' already in use in RequestNavigator.""");
    }

    _streams[routeName] = _createStreamControllerWithHandler(handler);
  }

  /**
   * When [Router] matches nothing then [handler] will be called (through the
   * returned [Stream]).
   */
  void setDefaultHandler(dynamic handler){
    _defaultStreamController = _createStreamControllerWithHandler(handler);
  }

  /**
   * [HttpRequest.uri.path] is matched agains [Router], whole [HttpRequest] is
   * filtered through [Filter] and if passes all then [HttpRequest] is inserted
   * to the correspondig [Stream].
   */
  void processHttpRequest(HttpRequest req){
    var matchInfo = _router.match(req.uri.path);
    if(matchInfo != null){
      if(_streams.containsKey(matchInfo[0])){
        _streams[matchInfo[0]]
          .add(new RequestHandlerParameters(req, matchInfo[1]));
      }
      else{
        throw new ArgumentError("Stream not found for '${matchInfo[0]}'");
      }
    }
    else{
      _defaultStreamController.add(new RequestHandlerParameters(req, {}));
    }
  }
}
