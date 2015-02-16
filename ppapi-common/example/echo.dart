library ppapi_common.example.echo;

import 'dart:html';
import 'package:ppapi_common/nacl_module.dart';

class EchoModule extends NaClModule {

  factory EchoModule(String selector) {
    var wrapper = document.querySelector(selector);
    return new EchoModule._internal(wrapper);
  }
  
  EchoModule._internal(wrapper) : super(wrapper, 'echo', 'pnacl/Release');

  void onMessage(event) {
    print(event.data);
    //window.alert('${event.data}');
  }
}

EchoModule module;

main() {
  querySelector('#sendButton').onClick.listen(submitForm);
  module = new EchoModule('#listener');
}

void submitForm(Event e) {
  e.preventDefault();
  TextInputElement messageInput = querySelector('#messageInput');
  
  if (!module.loaded) {
    updateStatus("LOADING");
    module.loadModule().then((_) {
      updateStatus("RUNNING");
      //module.postMessage(messageInput.value);
      module.runCommand("echo", [messageInput.value]);
    }, onError: (_) {
      if (module.status == ModuleStatus.EXITED) {
        updateStatus('EXITED [${module.exitStatus}]');
      } else {
        updateStatus('CRASHED');        
      }
    });
  } else {
    //module.postMessage(messageInput.value);
    module.runCommand("echo", [messageInput.value]);
  }
}

updateStatus(String message) {
  Element statusField = querySelector('#statusField');
  if (statusField != null) {
    statusField.text = message;
  }
}
