//=============================================================================
// 📄 Archivo: responsible_access_gate.dart
// 🔐 Gate por inactividad / salida de la app (SKANO)
// ✅ Versión mejorada con WARNING previo (60s)
//=============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'responsible_access_screen.dart';

class ResponsibleAccessGate extends StatefulWidget {
  const ResponsibleAccessGate({
    super.key,
    required this.child,
    required this.navigatorKey,
    this.idleMinutes = 15, // 🔥 más realista
    this.warningSeconds = 60,
  });

  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;
  final int idleMinutes;
  final int warningSeconds;

  @override
  State<ResponsibleAccessGate> createState() => _ResponsibleAccessGateState();
}

class _ResponsibleAccessGateState extends State<ResponsibleAccessGate>
    with WidgetsBindingObserver {
  DateTime? _lastBackgroundAt;
  DateTime _lastInteraction = DateTime.now();

  Timer? _idleTimer;
  Timer? _warningTimer;

  bool _showingGate = false;
  bool _showingWarning = false;

  int _countdown = 0;

  // ================= INIT =================
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startIdleTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _idleTimer?.cancel();
    _warningTimer?.cancel();
    super.dispose();
  }

  // ================= APP LIFECYCLE =================
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _lastBackgroundAt = DateTime.now();
      return;
    }

    if (state == AppLifecycleState.resumed) {
      _tryShowFromBackground();
    }
  }

  // ================= INACTIVIDAD =================
  void _startIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      final diff = DateTime.now().difference(_lastInteraction);

      final warningTime =
          Duration(minutes: widget.idleMinutes) -
              Duration(seconds: widget.warningSeconds);

      if (!_showingWarning && diff >= warningTime) {
        _showWarning();
      }

      if (diff >= Duration(minutes: widget.idleMinutes)) {
        _showGate();
      }
    });
  }

  void _registerInteraction() {
    _lastInteraction = DateTime.now();

    if (_showingWarning) {
      Navigator.of(context, rootNavigator: true).pop();
      _showingWarning = false;
      _warningTimer?.cancel();
    }
  }

  // ================= WARNING =================
  void _showWarning() {
    if (_showingWarning || _showingGate) return;

    final ctx = widget.navigatorKey.currentContext;
    if (ctx == null) return;

    _showingWarning = true;
    _countdown = widget.warningSeconds;

    _warningTimer?.cancel();
    _warningTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) {
      _countdown--;

      if (_countdown <= 0) {
        timer.cancel();
      }

      if (mounted) setState(() {});
    });

    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: const Color(0xFF121212),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              "Sesión inactiva",
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              "Por seguridad, tu sesión se bloqueará en $_countdown segundos.",
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A6CFF),
                ),
                onPressed: () {
                  _warningTimer?.cancel();
                  Navigator.of(context).pop();
                  _showingWarning = false;
                  _lastInteraction = DateTime.now();
                },
                child: const Text("Seguir usando",
                    style: TextStyle(color: Colors.black)),
              ),
            ],
          );
        },
      ),
    );
  }

  // ================= GATE =================
  Future<void> _showGate() async {
    if (_showingGate) return;

    final ctx = widget.navigatorKey.currentContext;
    if (ctx == null) return;

    _showingGate = true;

    await Future.delayed(const Duration(milliseconds: 50));

    await Navigator.of(ctx, rootNavigator: true).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const ResponsibleAccessScreen(),
      ),
    );

    _showingGate = false;
    _lastInteraction = DateTime.now();
    _lastBackgroundAt = DateTime.now();
  }

  // ================= BACKGROUND CHECK =================
  Future<void> _tryShowFromBackground() async {
    if (_showingGate || _lastBackgroundAt == null) return;

    final diff = DateTime.now().difference(_lastBackgroundAt!);
    if (diff >= Duration(minutes: widget.idleMinutes)) {
      await _showGate();
    }
  }

  // ================= UI WRAPPER =================
  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _registerInteraction(),
      onPointerMove: (_) => _registerInteraction(),
      onPointerUp: (_) => _registerInteraction(),
      onPointerSignal: (_) => _registerInteraction(),
      child: widget.child,
    );
  }
}
