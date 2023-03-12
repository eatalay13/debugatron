import 'dart:async';
import 'dart:isolate';

import 'package:flutter/material.dart';

import 'application_profile_manager.dart';

class Debugatron {
  static late Debugatron _instance;
  static GlobalKey<NavigatorState>? _navigatorKey;

  /// Root widget which will be ran
  final Widget? rootWidget;

  ///Run app function which will be ran
  final void Function()? runAppFunction;

  /// Should Debugatron run WidgetsFlutterBinding.ensureInitialized() during initialization.
  final bool ensureInitialized;

  /// Instance of navigator key
  static GlobalKey<NavigatorState>? get navigatorKey {
    return _navigatorKey;
  }

  /// Builds Debugatron instance
  Debugatron({
    this.rootWidget,
    this.runAppFunction,
    this.ensureInitialized = false,
    GlobalKey<NavigatorState>? navigatorKey,
  }) : assert(
          rootWidget != null || runAppFunction != null,
          "You need to provide rootWidget or runAppFunction",
        ) {
    _configure(navigatorKey);
  }

  void _configure(GlobalKey<NavigatorState>? navigatorKey) {
    _instance = this;
    _configureNavigatorKey(navigatorKey);
    _setupErrorHooks();
  }

  void _configureNavigatorKey(GlobalKey<NavigatorState>? navigatorKey) {
    if (navigatorKey != null) {
      _navigatorKey = navigatorKey;
    } else {
      _navigatorKey = GlobalKey<NavigatorState>();
    }
  }

  Future _setupErrorHooks() async {
    FlutterError.onError = (FlutterErrorDetails details) async {
      //_reportError(details.exception, details.stack, errorDetails: details);
    };

    ///Web doesn't have Isolate error listener support
    if (!ApplicationProfileManager.isWeb()) {
      Isolate.current.addErrorListener(
        RawReceivePort((dynamic pair) async {
          //final isolateError = pair as List<dynamic>;
          // _reportError(isolateError.first.toString(), isolateError.last.toString());
        })
            .sendPort,
      );
    }

    if (rootWidget != null) {
      _runZonedGuarded(() {
        runApp(rootWidget!);
      });
    } else if (runAppFunction != null) {
      _runZonedGuarded(() {
        runAppFunction!();
      });
    } else {
      throw ArgumentError("Provide rootWidget or runAppFunction to Debugatron.");
    }
  }

  void _runZonedGuarded(void Function() callback) {
    runZonedGuarded<Future<void>>(() async {
      if (ensureInitialized) {
        WidgetsFlutterBinding.ensureInitialized();
      }
      callback();
    }, (dynamic error, StackTrace stackTrace) {
      //_reportError(error, stackTrace);
    });
  }

  /// Report checked error (error caught in try-catch block). Debugatron will treat
  /// this as normal exception and pass it to handlers.
  static void reportCheckedError(dynamic error, dynamic stackTrace) {
    dynamic errorValue = error;
    dynamic stackTraceValue = stackTrace;
    errorValue ??= "undefined error";
    stackTraceValue ??= StackTrace.current;
    //_instance._reportError(error, stackTrace);
  }

  BuildContext? getContext() {
    return navigatorKey?.currentState?.overlay?.context;
  }

  bool isContextValid() {
    return navigatorKey?.currentState?.overlay != null;
  }

  ///Get current Debugatron instance.
  static Debugatron getInstance() {
    return _instance;
  }
}
