// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_all;

import "common_test.dart" as common_test;
import "server_test.dart" as server_test;
import "client_test.dart" as client_test;

import 'package:unittest/unittest.dart';
import 'package:unittest/vm_config.dart';

main() {
  run(new VMConfiguration());
}

run(configuration) {
  unittestConfiguration = configuration;

  common_test.main();
  server_test.main();
  client_test.main();
}