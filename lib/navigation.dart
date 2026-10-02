import 'package:flutter/material.dart';

/// Global navigator used to unwind pushed routes (e.g. the report screen) when
/// the server is reset while they sit on top of the login screen.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
