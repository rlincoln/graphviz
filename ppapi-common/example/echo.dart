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
    updateStatus("LOADING");
    module.loadModule().then((_) {
      updateStatus("RUNNING");
      module.postMessage(messageInput.value);
    }, onError: (_) {
      if (module.status == ModuleStatus.EXITED) {
        updateStatus('EXITED [${module.exitStatus}]');
      } else {
        updateStatus('CRASHED');        
      }
    });
  } else {
    module.postMessage(messageInput.value);
  }
}

var statusText = 'NO-STATUS';

updateStatus([String opt_message]) {
  if (opt_message != null) {
    statusText = opt_message;
  }
  var statusField = document.getElementById('statusField');
  if (statusField) {
    statusField.appendText(statusText);
  }
}