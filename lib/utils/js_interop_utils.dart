import 'dart:js_util' as js_util;

T dartify<T>(dynamic jsObject) {
  return js_util.dartify(jsObject) as T;
}

dynamic jsify(Object dartObject) {
  return js_util.jsify(dartObject);
}

Future<T> handleThenable<T>(dynamic promise) {
  return js_util.promiseToFuture<T>(promise);
}
