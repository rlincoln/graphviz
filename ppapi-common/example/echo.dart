library ppapi_common.example.echo;

import 'dart:html';
import 'dart:async';
import 'package:ppapi_common/nacl_module.dart';

final module = new EchoModule('#listener');

class EchoModule extends AsyncNaClModule {

  factory EchoModule(String selector) {
    var wrapper = document.querySelector(selector);
    return new EchoModule._internal(wrapper);
  }
  
  EchoModule._internal(wrapper) : super(wrapper, 'echo', 'pnacl/Release');

  Future echo(message) {
    return runCommand('echo', [message]);
  }
}

void submitForm(Event e) {
  e.preventDefault();
  TextInputElement messageInput = querySelector('#messageInput');
  
  if (!module.loaded) {
    updateStatus("LOADING");
    module.loadModule().then((_) {
      updateStatus("RUNNING");
      module.echo(messageInput.value).then((retval) {
        print(retval);  
      });
    }, onError: (_) {
      if (module.status == ModuleStatus.EXITED) {
        updateStatus('EXITED [${module.exitStatus}]');
      } else {
        updateStatus('CRASHED');        
      }
    });
  } else {
    module.echo(messageInput.value).then((retval) {
      print(retval);  
    });
  }
}

updateStatus(String message) {
  Element statusField = querySelector('#statusField');
  if (statusField != null) {
    statusField.text = message;
  }
}

main() {
  querySelector('#sendButton').onClick.listen(submitForm);
}
