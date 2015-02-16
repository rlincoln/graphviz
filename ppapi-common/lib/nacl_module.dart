library ppapi_common.pnacl_module;

import 'dart:async';
import 'dart:html';
import 'dart:math' show Random;
import 'dart:js' show context, JsObject;

enum ModuleStatus {
  /// NaCl module not loaded.
  NO_STATUS,
  LOADING,
  RUNNING,
  /// NaCl module failed to load.
  ERROR,
  /// Browser can not communicate with module.
  EXITED,
  CRASHED
}

enum Toolchain {
  NEWLIB, GLIBC, PNACL, LINUX, MAX, WIN
}

abstract class NaClModule {
  String name;
  String get id => '${name}_module';
  String path;
  String src;
  String mimetype = 'application/x-pnacl';
  num width = 0, height = 0;
  
  Element _wrapper;
  JsObject _jsModule = null;
  
  Completer _loadCompleter;
  bool _loaded = false;
  bool get loaded => _loaded;
  
  ModuleStatus _status = ModuleStatus.NO_STATUS;
  ModuleStatus get status => _status;    
  
  NaClModule(this._wrapper, this.name, this.path) {
    if (_wrapper == null) {
      throw new ArgumentError.notNull('wrapper');
    }
    
    _wrapper.addEventListener('load', onLoad, true);
    _wrapper.addEventListener('message', onMessage, true);  
    _wrapper.addEventListener('error', _onError, true);
    _wrapper.addEventListener('crash', _onCrash, true);
  }
  
  Future loadModule() {
    var moduleEl = _createNaClModule();
    _loadCompleter = new Completer();
    _status = ModuleStatus.LOADING;
    _wrapper.append(moduleEl);
    return _loadCompleter.future;
  }
  
  void onLoad(Event event) {
    _status = ModuleStatus.RUNNING;
    var jsDoc = new JsObject.fromBrowserObject(context["document"]);
    _jsModule = new JsObject.fromBrowserObject(jsDoc.callMethod("getElementById", [id]));
    _loaded = true;
    if (_loadCompleter != null) {
      _loadCompleter.complete(_loaded);
      _loadCompleter = null;
    }
  }
  
  void onMessage(Event event);

  /// Called when the NaCl module fails to load.
  void _onError(event) {
    _status = ModuleStatus.ERROR;
    if (_loadCompleter != null) {
      _loadCompleter.completeError(event);
      _loadCompleter = null;
    }
  }

  /// Called when the browser can not communicate with the module.
  _onCrash(event) {
    if (_jsModule['exitStatus'] == -1) {
      _status = ModuleStatus.CRASHED;
    } else {
      _status = ModuleStatus.EXITED;
    }
    if (_loadCompleter != null) {
      _loadCompleter.completeError(event);
      _loadCompleter = null;
    }
  }
  
  int get exitStatus => _jsModule['exitStatus'];
  
  void postMessage(message) {
    if (_jsModule == null) {
      return;
    }
    if (message is Map || message is Iterable) {
      message = new JsObject.jsify(message);
    } else if (message is! String && message is! num) {
      throw new ArgumentError.value(message, 'message', "unsupported message type");
    }
    _jsModule.callMethod("postMessage", [message]);
  }
  
  runCommand(String cmd, List args) {
    var message = {
      'cmd': cmd,
      'args': args
    };
    postMessage(message);
  } 
    
  Element _createNaClModule() {
    var embed = new Element.tag('embed');
    embed.attributes['name'] = name;
    embed.attributes['id'] = id;
    embed.attributes['width'] = width.toString();
    embed.attributes['height'] = height.toString();
    embed.attributes['path'] = path;
    embed.attributes['src'] = '$path/$name.nmf';
    embed.attributes['type'] = mimetype;
    return embed;
  }
}

abstract class AsyncNaClModule extends NaClModule {
  final Random _random = new Random();
  final Map<String, Completer> _messageCompleters = {};

  AsyncNaClModule(wrapper, String packagePath, String manifestName) :
    super(wrapper, packagePath, manifestName);
  
  dynamic get _nextId => _random.nextInt(1 << 31);
  
  Future postMessage(message) {
    final id = _nextId;
    var completer = new Completer();
    _messageCompleters[id] = completer;
    
    var fullMessage = {
      'id': id,
      'payload': message
    };
    super.postMessage(fullMessage);
    
    return completer.future;
  }
  
  void onMessage(event) {
    final message = event.data;
    if (message is! Map) {
      throw new ArgumentError.value(message);
    }
    if (!message.containsKey('id') || !message.containsKey('payload')) {
      throw new ArgumentError.value(message);
    } 
    var id = message['id'];
    var payload = message['payload'];
    if (!_messageCompleters.containsKey(id)) {
      throw new StateError('received message with unknown id: $id');
    }
    _messageCompleters[id].complete(payload);
    _messageCompleters.remove(id);
  }
  
  Future runCommand(String cmd, List args) {    
    var message = {
      'cmd': cmd,
      'args': args
    };
    return postMessage(message);
  } 
}