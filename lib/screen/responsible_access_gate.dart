//=============================================================================
// 📄 Archivo: responsible_access_gate.dart
// 🔐 Gate por inactividad / salida de la app (SKANO)
// ✅ Warning previo con cuenta regresiva real
// ✅ Evita diálogos duplicados
// ✅ Bloqueo por app en segundo plano
// ✅ Compatible con ResponsibleAccessScreen
//=============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'responsible_access_screen.dart';

class ResponsibleAccessGate extends StatefulWidget {
  const ResponsibleAccessGate({
    super.key,
    required this.child,
    required this.navigatorKey,
    this.idleMinutes = 15,
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
  static const Color neonBlue = Color(0xFF0A6CFF);
  static const Color darkBg = Color(0xFF07091F);
  static const Color cardBg = Color(0xFF101827);

  DateTime? _lastBackgroundAt;
  DateTime _lastInteraction = DateTime.now();

  Timer? _idleTimer;
  Timer? _warningTimer;

  bool _showingGate = false;
  bool _showingWarning = false;
  bool _dialogOpen = false;

  int _countdown = 0;

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
      _warningTimer?.cancel();
      return;
    }

    if (state == AppLifecycleState.resumed) {
      _tryShowFromBackground();
    }
  }

  // ================= INACTIVIDAD =================
  void _startIdleTimer() {
    _idleTimer?.cancel();

    _idleTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _showingGate) return;

      final now = DateTime.now();
      final diff = now.difference(_lastInteraction);

      final idleDuration = Duration(minutes: widget.idleMinutes);
      final warningDuration = Duration(seconds: widget.warningSeconds);
      final warningStart = idleDuration - warningDuration;

      if (!_showingWarning && diff >= warningStart && diff < idleDuration) {
        _showWarning();
        return;
      }

      if (diff >= idleDuration) {
        _dismissWarningIfOpen();
        _showGate();
      }
    });
  }

  void _registerInteraction() {
    if (_showingGate) return;

    _lastInteraction = DateTime.now();

    if (_showingWarning) {
      _dismissWarningIfOpen();
    }
  }

  // ================= WARNING =================
  Future<void> _showWarning() async {
    if (_showingWarning || _showingGate || _dialogOpen) return;

    final ctx = widget.navigatorKey.currentContext;
    if (ctx == null || !mounted) return;

    _showingWarning = true;
    _dialogOpen = true;
    _countdown = widget.warningSeconds;

    _warningTimer?.cancel();
    _warningTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_showingWarning) {
        timer.cancel();
        return;
      }

      _countdown--;

      if (_countdown <= 0) {
        timer.cancel();
        _dismissWarningIfOpen();
        _showGate();
        return;
      }

      setState(() {});
    });

    await showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: StatefulBuilder(
            builder: (context, setStateDialog) {
              // Refresca el diálogo cada vez que cambia el State principal.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_showingWarning && mounted) {
                  try {
                    setStateDialog(() {});
                  } catch (_) {}
                }
              });

              return AlertDialog(
                backgroundColor: cardBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: Colors.white.withOpacity(0.10)),
                ),
                titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
                contentPadding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
                actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                title: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: neonBlue.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: neonBlue.withOpacity(0.35)),
                      ),
                      child: const Icon(
                        Icons.timer_outlined,
                        color: neonBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Sesión inactiva',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Por seguridad, SKANO pausará el acceso si no confirmas que sigues usando la aplicación.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.72),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: darkBg.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$_countdown',
                            style: const TextStyle(
                              color: neonBlue,
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'segundos restantes',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              minHeight: 7,
                              value: (_countdown / widget.warningSeconds)
                                  .clamp(0.0, 1.0),
                              backgroundColor: Colors.white.withOpacity(0.10),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                neonBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: neonBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        _lastInteraction = DateTime.now();
                        _dismissWarningIfOpen();
                      },
                      child: const Text(
                        'SEGUIR USANDO SKANO',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    ).whenComplete(() {
      _dialogOpen = false;
      _showingWarning = false;
      _warningTimer?.cancel();
    });
  }

  void _dismissWarningIfOpen() {
    _warningTimer?.cancel();
    _showingWarning = false;

    final nav = widget.navigatorKey.currentState;
    if (_dialogOpen && nav != null && nav.canPop()) {
      try {
        nav.pop();
      } catch (_) {}
    }

    _dialogOpen = false;
  }

  // ================= GATE =================
  Future<void> _showGate() async {
    if (_showingGate) return;

    final ctx = widget.navigatorKey.currentContext;
    if (ctx == null || !mounted) return;

    _showingGate = true;
    _warningTimer?.cancel();
    _showingWarning = false;

    await Future.delayed(const Duration(milliseconds: 80));

    if (!mounted) return;

    await Navigator.of(ctx, rootNavigator: true).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const ResponsibleAccessScreen(),
      ),
    );

    if (!mounted) return;

    _showingGate = false;
    _dialogOpen = false;
    _lastInteraction = DateTime.now();
    _lastBackgroundAt = DateTime.now();
  }

  // ================= BACKGROUND CHECK =================
  Future<void> _tryShowFromBackground() async {
    if (_showingGate || _lastBackgroundAt == null) return;

    final diff = DateTime.now().difference(_lastBackgroundAt!);

    if (diff >= Duration(minutes: widget.idleMinutes)) {
      _dismissWarningIfOpen();
      await _showGate();
      return;
    }

    _lastInteraction = DateTime.now();
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
