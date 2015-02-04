// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
library ppapi_common;

import 'dart:html';

// Set to true when the Document is loaded IFF "test=true" is in the query
// string.
bool isTest = false;

// Set to true when loading a "Release" NaCl module, false when loading a
// "Debug" NaCl module.
bool isRelease = true;

class NaClModule {

  bool _isHostToolchain(String tool) {
    return tool == 'win' || tool == 'linux' || tool == 'mac';
  }

  /**
   * Return the mime type for NaCl plugin.
   *
   * @param {string} tool The name of the toolchain, e.g. "glibc", "newlib" etc.
   * @return {string} The mime-type for the kind of NaCl plugin matching
   * the given toolchain.
   */
  String _mimeTypeForTool(String tool) {
    // For NaCl modules use application/x-nacl.
    var mimetype = 'application/x-nacl';
    if (_isHostToolchain(tool)) {
      // For non-NaCl PPAPI plugins use the x-ppapi-debug/release
      // mime type.
      if (isRelease)
        mimetype = 'application/x-ppapi-release';
      else
        mimetype = 'application/x-ppapi-debug';
    } else if (tool == 'pnacl') {
      mimetype = 'application/x-pnacl';
    }
    return mimetype;
  }

  /**
   * Check if the browser supports NaCl plugins.
   *
   * @param {string} tool The name of the toolchain, e.g. "glibc", "newlib" etc.
   * @return {bool} True if the browser supports the type of NaCl plugin
   * produced by the given toolchain.
   */
  bool _browserSupportsNaCl(String tool) {
    // Assume host toolchains always work with the given browser.
    // The below mime-type checking might not work with
    // --register-pepper-plugins.
    if (_isHostToolchain(tool)) {
      return true;
    }
    var mimetype = _mimeTypeForTool(tool);
    return window.navigator.mimeTypes[mimetype] != null;
  }

  /**
   * Inject a script into the DOM, and call a callback when it is loaded.
   *
   * @param {string} url The url of the script to load.
   * @param {Function} onload The callback to call when the script is loaded.
   * @param {Function} onerror The callback to call if the script fails to load.
   */
  void _injectScript(String url, Function onload, Function onerror) {
    var scriptEl = document.createElement('script');
    scriptEl.type = 'text/javascript';
    scriptEl.src = url;
    scriptEl.onload = onload;
    if (onerror != null) {
      scriptEl.addEventListener('error', onerror, false);
    }
    document.head.append(scriptEl);
  }

  /**
   * Run all tests for this example.
   *
   * @param {Object} moduleEl The module DOM element.
   */
  /*void runTests(Element moduleEl) {
    console.log('runTests()');
    common.tester = new Tester();

    // All NaCl SDK examples are OK if the example exits cleanly; (i.e. the
    // NaCl module returns 0 or calls exit(0)).
    //
    // Without this exception, the browser_tester thinks that the module
    // has crashed.
    common.tester.exitCleanlyIsOK();

    common.tester.addAsyncTest('loaded', function(test) {
      test.pass();
    });

    if (typeof window.addTests !== 'undefined') {
      window.addTests();
    }

    common.tester.waitFor(moduleEl);
    common.tester.run();
  }*/

  /**
   * Create the Native Client <embed> element as a child of the DOM element
   * named "listener".
   *
   * @param {string} name The name of the example.
   * @param {string} tool The name of the toolchain, e.g. "glibc", "newlib" etc.
   * @param {string} path Directory name where .nmf file can be found.
   * @param {number} width The width to create the plugin.
   * @param {number} height The height to create the plugin.
   * @param {Object} attrs Dictionary of attributes to set on the module.
   */
  void createNaClModule(String name, String tool, String path, num width, num height, [Map<String, String> attrs=null]) {
    var moduleEl = document.createElement('embed');
    moduleEl.setAttribute('name', 'nacl_module');
    moduleEl.setAttribute('id', 'nacl_module');
    moduleEl.setAttribute('width', '$width');
    moduleEl.setAttribute('height', '$height');
    moduleEl.setAttribute('path', path);
    moduleEl.setAttribute('src', path + '/' + name + '.nmf');

    // Add any optional arguments
    if (attrs != null) {
      attrs.forEach((key, value) {
        moduleEl.setAttribute(key, value);
      });
    }

    var mimetype = _mimeTypeForTool(tool);
    moduleEl.setAttribute('type', mimetype);

    // The <EMBED> element is wrapped inside a <DIV>, which has both a 'load'
    // and a 'message' event listener attached.  This wrapping method is used
    // instead of attaching the event listeners directly to the <EMBED> element
    // to ensure that the listeners are active before the NaCl module 'load'
    // event fires.
    var listenerDiv = document.getElementById('listener');
    listenerDiv.append(moduleEl);

    // Request the offsetTop property to force a relayout. As of Apr 10, 2014
    // this is needed if the module is being loaded on a Chrome App's
    // background page (see crbug.com/350445).
    moduleEl.offsetTop;

    // Host plugins don't send a moduleDidLoad message. We'll fake it here.
    var isHost = _isHostToolchain(tool);
    if (isHost) {
      window.setTimeout(() {
        moduleEl.readyState = 1;
        moduleEl.dispatchEvent(new CustomEvent('loadstart'));
        moduleEl.readyState = 4;
        moduleEl.dispatchEvent(new CustomEvent('load'));
        moduleEl.dispatchEvent(new CustomEvent('loadend'));
      }, 100);  // 100 ms
    }

    // This is code that is only used to test the SDK.
    if (isTest) {
      var loadNaClTest = () {
        _injectScript('nacltest.js', () {
          runTests(moduleEl);
        });
      };

      // Try to load test.js for the example. Whether or not it exists, load
      // nacltest.js.
      _injectScript('test.js', loadNaClTest, loadNaClTest);
    }
  }

  /**
   * Add the default "load" and "message" event listeners to the element with
   * id "listener".
   *
   * The "load" event is sent when the module is successfully loaded. The
   * "message" event is sent when the naclModule posts a message using
   * PPB_Messaging.PostMessage() (in C) or pp::Instance().PostMessage() (in
   * C++).
   */
  void attachDefaultListeners() {
    var listenerDiv = document.getElementById('listener');
    listenerDiv.addEventListener('load', _moduleDidLoad, true);
    listenerDiv.addEventListener('message', handleMessage, true);
    listenerDiv.addEventListener('error', _handleError, true);
    listenerDiv.addEventListener('crash', _handleCrash, true);
    if (window.attachListeners != null) {
      window.attachListeners();
    }
  }

  /**
   * Called when the NaCl module fails to load.
   *
   * This event listener is registered in createNaClModule above.
   */
  void _handleError(event) {
    // We can't use common.naclModule yet because the module has not been
    // loaded.
    var moduleEl = document.getElementById('nacl_module');
    updateStatus('ERROR [${moduleEl.lastError}]');
  }

  /**
   * Called when the Browser can not communicate with the Module
   *
   * This event listener is registered in attachDefaultListeners above.
   */
  _handleCrash(event) {
    if (common.naclModule.exitStatus == -1) {
      updateStatus('CRASHED');
    } else {
      updateStatus('EXITED [${common.naclModule.exitStatus}]');
    }
    if (window.handleCrash != null) {
      window.handleCrash(common.naclModule.lastError);
    }
  }

  /**
   * Called when the NaCl module is loaded.
   *
   * This event listener is registered in attachDefaultListeners above.
   */
  _moduleDidLoad() {
    common.naclModule = document.getElementById('nacl_module');
    updateStatus('RUNNING');

    if (window.moduleDidLoad != null) {
      window.moduleDidLoad();
    }
  }

  /**
   * Hide the NaCl module's embed element.
   *
   * We don't want to hide by default; if we do, it is harder to determine that
   * a plugin failed to load. Instead, call this function inside the example's
   * "moduleDidLoad" function.
   *
   */
  hideModule() {
    // Setting common.naclModule.style.display = "None" doesn't work; the
    // module will no longer be able to receive postMessages.
    common.naclModule.style.height = '0';
  }

  /**
   * Remove the NaCl module from the page.
   */
  removeModule() {
    common.naclModule.parentNode.removeChild(common.naclModule);
    common.naclModule = null;
  }

  /**
   * Return true when |s| starts with the string |prefix|.
   *
   * @param {string} s The string to search.
   * @param {string} prefix The prefix to search for in |s|.
   */
  static bool _startsWith(String s, String prefix) {
    // indexOf would search the entire string, lastIndexOf(p, 0) only checks at
    // the first index. See: http://stackoverflow.com/a/4579228
    return s.lastIndexOf(prefix, 0) == 0;
  }

  /** Maximum length of logMessageArray. */
  final maxLogMessageLength = 20;

  /** An array of messages to display in the element with id "log". */
  var logMessageArray = [];

  /**
   * Add a message to an element with id "log".
   *
   * This function is used by the default "log:" message handler.
   *
   * @param {string} message The message to log.
   */
  logMessage(String message) {
    logMessageArray.add(message);
    if (logMessageArray.length > maxLogMessageLength)
      logMessageArray.shift();

    document.getElementById('log').text = logMessageArray.join('\n');
    print(message);
  }

  Map defaultMessageTypes;// = {'alert': alert, 'log': logMessage};

  /**
   * Called when the NaCl module sends a message to JavaScript (via
   * PPB_Messaging.PostMessage())
   *
   * This event listener is registered in createNaClModule above.
   *
   * @param {Event} message_event A message event. message_event.data contains
   *     the data sent from the NaCl module.
   */
  handleMessage(message_event) {
    if (message_event.data is String) {
      for (var type in defaultMessageTypes) {
        if (defaultMessageTypes.hasOwnProperty(type)) {
          if (_startsWith(message_event.data, type + ':')) {
            func = defaultMessageTypes[type];
            func(message_event.data.slice(type.length + 1));
            return;
          }
        }
      }
    }

    if (window.handleMessage != null) {
      window.handleMessage(message_event);
      return;
    }

    logMessage('Unhandled message: ${message_event.data}');
  }

  /**
   * Called when the DOM content has loaded; i.e. the page's document is fully
   * parsed. At this point, we can safely query any elements in the document via
   * document.querySelector, document.getElementById, etc.
   *
   * @param {string} name The name of the example.
   * @param {string} tool The name of the toolchain, e.g. "glibc", "newlib" etc.
   * @param {string} path Directory name where .nmf file can be found.
   * @param {number} width The width to create the plugin.
   * @param {number} height The height to create the plugin.
   * @param {Object} attrs Optional dictionary of additional attributes.
   */
  void domContentLoaded(String name, String tool, String path, num width,
      num height, [Map<String, String> attrs=null]) {
    // If the page loads before the Native Client module loads, then set the
    // status message indicating that the module is still loading.  Otherwise,
    // do not change the status message.
    updateStatus('Page loaded.');
    if (!_browserSupportsNaCl(tool)) {
      updateStatus(
          'Browser does not support NaCl ($tool), or NaCl is disabled');
    } else if (common.naclModule == null) {
      updateStatus('Creating embed: $tool');

      // We use a non-zero sized embed to give Chrome space to place the bad
      // plug-in graphic, if there is a problem.
      width = width != null ? width : 200;
      height = height != null ? height : 200;
      attachDefaultListeners();
      createNaClModule(name, tool, path, width, height, attrs);
    } else {
      // It's possible that the Native Client module onload event fired
      // before the page's onload event.  In this case, the status message
      // will reflect 'SUCCESS', but won't be displayed.  This call will
      // display the current message.
      updateStatus('Waiting.');
    }
  }

  /** Saved text to display in the element with id 'statusField'. */
  var statusText = 'NO-STATUSES';

  /**
   * Set the global status message. If the element with id 'statusField'
   * exists, then set its HTML to the status message as well.
   *
   * @param {string} opt_message The message to set. If null or undefined, then
   *     set element 'statusField' to the message from the last call to
   *     updateStatus.
   */
  updateStatus([String opt_message=null]) {
    if (opt_message != null) {
      statusText = opt_message;
    }
    var statusField = document.getElementById('statusField');
    if (statusField) {
      statusField.innerHTML = statusText;
    }
  }

  /** A reference to the NaCl module, once it is loaded. */
  var naclModule = null;
}

// The symbols to export
// attachDefaultListeners: attachDefaultListeners,
// domContentLoaded: domContentLoaded,
// createNaClModule: createNaClModule,
// hideModule: hideModule,
// removeModule: removeModule,
// logMessage: logMessage,
// updateStatus: updateStatus

// Listen for the DOM content to be loaded. This event is fired when parsing of
// the page's document has finished.
main() {
  var body = document.body;

  // The data-* attributes on the body can be referenced via body.dataset.
  if (body.dataset) {
    var loadFunction;
    if (!body.dataset.customLoad) {
      loadFunction = common.domContentLoaded;
    } else if (window.domContentLoaded != null) {
      loadFunction = window.domContentLoaded;
    }

    // From https://developer.mozilla.org/en-US/docs/DOM/window.location
    Map searchVars = {};
    if (window.location.search.length > 1) {
      var pairs = window.location.search.substring(1).split('&');
      for (var key_ix = 0; key_ix < pairs.length; key_ix++) {
        var keyValue = pairs[key_ix].split('=');
        searchVars[unescape(keyValue[0])] =
            keyValue.length > 1 ? unescape(keyValue[1]) : '';
      }
    }

    if (loadFunction) {
      var toolchains = body.dataset['tools'].split(' ');
      var configs = body.dataset['configs'].split(' ');

      var attrs = {};
      if (body.dataset['attrs'] != null) {
        var attr_list = body.dataset['attrs'].split(' ');
        for (var key in attr_list) {
          var attr = attr_list[key].split('=');
          var k = attr[0];
          var v = attr[1];
          attrs[k] = v;
        }
      }

      var tc = toolchains.indexOf(searchVars['tc']) != -1 ?
          searchVars['tc'] : toolchains[0];

      // If the config value is included in the search vars, use that.
      // Otherwise default to Release if it is valid, or the first value if
      // Release is not valid.
      var config;
      if (configs.indexOf(searchVars['config']) != -1)
        config = searchVars['config'];
      else if (configs.indexOf('Release') != -1)
        config = 'Release';
      else
        config = configs[0];

      var pathFormat = body.dataset['path'];
      var path = pathFormat.replaceAll('{tc}', tc).replaceAll('{config}', config);

      isTest = searchVars['test'] == 'true';
      isRelease = path.toLowerCase().indexOf('release') != -1;

      loadFunction(body.dataset['name'], tc, path, body.dataset['width'],
                   body.dataset['height'], attrs);
    }
  }
}
