import "package:clean_router/client_browser.dart";
import 'dart:async';

void main() {
  new Future.delayed(new Duration(seconds: 5), () =>
    redirectPost('http://www.google.com/', {
       "ID": 1,
       "data" : "random data",
       "url" : "http://random.url+plus/",
    }));
}