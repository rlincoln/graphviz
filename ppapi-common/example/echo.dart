library ppapi_common.example.echo;

import 'dart:html';
import 'package:ppapi_common/nacl_module.dart';

class EchoModule extends NaClModule {

  factory EchoModule(String selector) {
    var wrapper = document.querySelector(selector);
    return new EchoModule._internal(wrapper);
  }
  
  EchoModule._internal(wrapper) : super(wrapper, 'echo', 'echo.nmf');

  void onMessage(event) {
    window.alert(event.data);
  }
}

EchoModule module;

main() {
  module = new EchoModule('#listener');
}

void submitForm(Event e) {
  e.preventDefault();
  TextInputElement messageInput = querySelector('#messageInput');
  
  if (!module.loaded) {
    module.loadModule().then((_) {
      module.postMessage(messageInput.value);
    });
  } else {
    module.postMessage(messageInput.value);
  }
}