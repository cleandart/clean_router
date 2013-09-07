
import 'package:router/router.dart';
import 'package:web_ui/web_ui.dart';

@observable
String activeRoute = 'Route';
@observable
String str = '';
@observable
num count = 0;
@observable
String sampleText = 'Click me!';

var viewParams;

class View {
  final routeName;

  View(this.routeName);

  void load(parameters) {
    activeRoute = routeName;
    viewParams = parameters;
    count = int.parse(viewParams['count']);
  }
  void unload() {

  }
}

void main() {
   var navigator = createNavigator([
    ['first', new Route('/first/url/{count}/'), new View('first')],
    ['second', new Route( '/second/url/{count}/'), new View('second')],
  ]);

  navigator.navigate('/second/url/4/');
}

void increment() {
  count++;
  viewParams['count'] = count.toString();
}