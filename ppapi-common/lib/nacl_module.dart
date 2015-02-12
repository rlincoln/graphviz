library ppapi_common.pnacl_module;

import 'dart:async';
import 'dart:html';
import 'dart:js' show context, JsObject;

abstract class NaClModule {
  String name = 'nacl_module';
  String id = 'nacl_module';
  String path;
  String src;
  String mimetype = 'application/x-pnacl';
  num width = 0, height = 0;
  
  Element _wrapper;
  var jsModule = null;
  
  Completer _completer;
  bool _loaded = false;
  bool get loaded => _loaded;
  
  NaClModule(this._wrapper, String packagePath, String manifestName) {
    if (_wrapper == null) {
      throw new ArgumentError.notNull('wrapper');
    }
    path = '/packages/$packagePath/';
    src = path + manifestName;
    
    _wrapper.addEventListener('load', onLoad, true);
    _wrapper.addEventListener('message', onMessage, true);  
  }
  
  Future loadModule() {
    _completer = new Completer();
    var moduleEl = _createNaClModule();    
    _wrapper.append(moduleEl);
    return _completer.future;
  }
  
  void onLoad(Event event) {
    var jsDoc = new JsObject.fromBrowserObject(context["document"]);
    jsModule = new JsObject.fromBrowserObject(jsDoc.callMethod("getElementById", [id]));
    _loaded = true;
    if (_completer != null) {
      _completer.complete(_loaded);
      _completer = null;
    }
  }
  
  void onMessage(Event event);
  
  void postMessage(message) {
    if (jsModule == null) {
      return;
    }
    if (message is Map || message is Iterable) {
      message = new JsObject.jsify(message);
    } else if (message is! String && message is! num) {
      throw new ArgumentError.value(message, 'message', "unsupported message type");
    }
    jsModule.callMethod("postMessage", [message]);
  }
    
  Element _createNaClModule() {
    var embed = new Element.tag('embed');
    embed.attributes['name'] = 'nacl_module';
    embed.attributes['id'] = 'nacl_module';
    embed.attributes['width'] = width.toString();
    embed.attributes['height'] = height.toString();
    embed.attributes['path'] = path;
    embed.attributes['src'] = src;
    embed.attributes['type'] = mimetype;
    return embed;
  }
}
