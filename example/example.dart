import "package:clean_router/client_browser.dart";
import "dart:html";

class SimpleView extends View {

  final message;

  SimpleView(this.message);

  void load(data) {
    window.alert(message);

  }
  void unload() {

  }
}

void main() {
  var navigator = createPageNavigator();

  var router = navigator.router;

  var view = new SimpleView("Hello world!");
  var defaultView = new SimpleView("Hello default!");

  router.registerRoute("example", new Route("/clean_router/example/example.html/"));

  navigator.registerView('example', view);
  navigator.registerDefaultView(defaultView);

}