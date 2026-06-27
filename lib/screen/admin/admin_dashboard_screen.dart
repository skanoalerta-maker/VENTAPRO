import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ================= ADMIN SCREENS =================
import 'admin_users_screen.dart';
import 'admin_review_users_screen.dart';
import 'admin_incomplete_users_screen.dart';
import 'admin_blocked_users_screen.dart';
import 'admin_company_requests_screen.dart';
import 'admin_vehicles_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_stolen_vehicles_screen.dart';
import 'admin_recovered_vehicles_screen.dart';
import 'admin_legal_risk_users_screen.dart';
import 'admin_reverification_users_screen.dart';
import 'admin_external_vehicles_screen.dart';
import 'admin_internal_console_screen.dart';
import 'admin_vehicle_upload_requests_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  static const Color neonBlue = Color(0xFF0A6CFF);

  Future<bool> _isAdmin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    final snap =
        await FirebaseFirestore.instance.collection("users").doc(uid).get();

    return snap.exists && snap.data()?["role"] == "admin";
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isAdmin(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFF0D0F14),
            body: Center(
              child: CircularProgressIndicator(color: neonBlue),
            ),
          );
        }

        if (snap.data != true) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              "/home",
              (_) => false,
            );
          });
          return const SizedBox.shrink();
        }

        return const _AdminDashboardBody();
      },
    );
  }
}

class _AdminDashboardBody extends StatelessWidget {
  static const Color neonBlue = Color(0xFF0A6CFF);

  const _AdminDashboardBody();

  @override
  Widget build(BuildContext context) {
    final usersStream =
        FirebaseFirestore.instance.collection("users").snapshots();

    final pendingUsersStream = FirebaseFirestore.instance
        .collection("users")
        .where("reviewPending", isEqualTo: true)
        .snapshots();

    final incompleteUsersStream =
        FirebaseFirestore.instance.collection("incomplete_users").snapshots();

    final blockedUsersStream = FirebaseFirestore.instance
        .collection("users")
        .where("blocked", isEqualTo: true)
        .snapshots();

    final companyRequestsStream = FirebaseFirestore.instance
        .collection("company_requests")
        .where("status", isEqualTo: "pending")
        .snapshots();

    final pendingVehiclesStream = FirebaseFirestore.instance
        .collection("vehicles")
        .where("status", isEqualTo: "pending_review")
        .snapshots();

    final pendingReportsStream = FirebaseFirestore.instance
        .collection("reports")
        .where("status", isEqualTo: "pending")
        .snapshots();

    final stolenVehiclesStream = FirebaseFirestore.instance
        .collection("stolen_vehicles")
        .where("status", whereIn: ["stolen", "reported"]).snapshots();

    final recoveredVehiclesStream = FirebaseFirestore.instance
        .collection("stolen_vehicles")
        .where("status", isEqualTo: "recovered")
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "ADMINISTRACIÓN · SKANO",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Chip(
              backgroundColor: neonBlue,
              label: Text(
                "ADMIN",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _heroBox(),
            const SizedBox(height: 18),
            _sectionTitle("Resumen general"),
            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot>(
              stream: usersStream,
              builder: (context, usersSnap) {
                return StreamBuilder<QuerySnapshot>(
                  stream: pendingUsersStream,
                  builder: (context, pendingSnap) {
                    return StreamBuilder<QuerySnapshot>(
                      stream: incompleteUsersStream,
                      builder: (context, incompleteSnap) {
                        return StreamBuilder<QuerySnapshot>(
                          stream: blockedUsersStream,
                          builder: (context, blockedSnap) {
                            final totalUsers =
                                usersSnap.hasData ? usersSnap.data!.docs.length : 0;
                            final pendingUsers = pendingSnap.hasData
                                ? pendingSnap.data!.docs.length
                                : 0;
                            final incompleteUsers = incompleteSnap.hasData
                                ? incompleteSnap.data!.docs.length
                                : 0;
                            final blockedUsers = blockedSnap.hasData
                                ? blockedSnap.data!.docs.length
                                : 0;

                            return Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _statBox(
                                        "Usuarios",
                                        totalUsers,
                                        Icons.groups_2_outlined,
                                        Colors.blueAccent,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _statBox(
                                        "Por aprobar",
                                        pendingUsers,
                                        Icons.person_search,
                                        Colors.orangeAccent,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _statBox(
                                        "Incompletos",
                                        incompleteUsers,
                                        Icons.mark_email_unread,
                                        Colors.amber,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _statBox(
                                        "Bloqueados",
                                        blockedUsers,
                                        Icons.lock,
                                        Colors.redAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 22),
            _sectionTitle("Pendientes operativos"),
            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot>(
              stream: pendingVehiclesStream,
              builder: (context, vehiclesSnap) {
                return StreamBuilder<QuerySnapshot>(
                  stream: pendingReportsStream,
                  builder: (context, reportsSnap) {
                    return StreamBuilder<QuerySnapshot>(
                      stream: companyRequestsStream,
                      builder: (context, companySnap) {
                        final pendingVehicles = vehiclesSnap.hasData
                            ? vehiclesSnap.data!.docs.length
                            : 0;
                        final pendingReports = reportsSnap.hasData
                            ? reportsSnap.data!.docs.length
                            : 0;
                        final companyRequests = companySnap.hasData
                            ? companySnap.data!.docs.length
                            : 0;

                        return _priorityPanel(
                          pendingVehicles: pendingVehicles,
                          pendingReports: pendingReports,
                          companyRequests: companyRequests,
                        );
                      },
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 22),
            _sectionTitle("Módulos del administrador"),
            const SizedBox(height: 10),

            _simpleCard(
              context,
              "Consola interna SKANO",
              "Acciones rápidas, mantenimiento, usuarios y vehículos",
              Icons.dashboard_customize,
              Colors.purpleAccent,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminInternalConsoleScreen(),
                ),
              ),
            ),
            
            _card(
              context,
              "Solicitudes subir vehículo",
              "Usuarios que piden autorización para subir vehículo sin pago",
              Icons.car_rental,
              Colors.cyanAccent,
              FirebaseFirestore.instance
                  .collection("vehicle_upload_requests")
                  .where("status", isEqualTo: "pending")
                  .snapshots(),
             () => Navigator.push(
               context,
               MaterialPageRoute(
                 builder: (_) => const AdminVehicleUploadRequestsScreen(),
               ),
             ),
           ),
            _card(
              context,
              "Todos los usuarios",
              "Base completa de usuarios registrados en SKANO",
              Icons.groups_2_outlined,
              Colors.blueAccent,
              usersStream,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminUsersScreen(),
                ),
              ),
            ),

            _card(
              context,
              "Usuarios pendientes",
              "Usuarios que requieren aprobación manual",
              Icons.person_search,
              Colors.orangeAccent,
              pendingUsersStream,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminReviewUsersScreen(),
                ),
              ),
            ),

            _card(
              context,
              "Usuarios incompletos",
              "Registros que no terminaron el flujo completo",
              Icons.mark_email_unread,
              Colors.amber,
              incompleteUsersStream,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminIncompleteUsersScreen(),
                ),
              ),
            ),

            _card(
              context,
              "Usuarios bloqueados",
              "Cuentas con bloqueo activo o revisión de seguridad",
              Icons.lock,
              Colors.redAccent,
              blockedUsersStream,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminBlockedUsersScreen(),
                ),
              ),
            ),

            _card(
              context,
              "Empresas pendientes",
              "Solicitudes de empresa esperando revisión",
              Icons.business,
              Colors.tealAccent,
              companyRequestsStream,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminCompanyRequestsScreen(),
                ),
              ),
            ),

            _card(
              context,
              "Vehículos pendientes",
              "Vehículos esperando validación administrativa",
              Icons.directions_car,
              Colors.lightBlueAccent,
              pendingVehiclesStream,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminVehiclesScreen(),
                ),
              ),
            ),

            _card(
              context,
              "Reportes pendientes",
              "Reportes ciudadanos esperando revisión",
              Icons.report,
              Colors.redAccent,
              pendingReportsStream,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminReportsScreen(),
                ),
              ),
            ),

            _card(
              context,
              "Vehículos robados activos",
              "Vehículos con encargo vigente en SKANO",
              Icons.warning_amber_rounded,
              Colors.orangeAccent,
              stolenVehiclesStream,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminStolenVehiclesScreen(),
                ),
              ),
            ),

            _card(
              context,
              "Vehículos recuperados",
              "Historial de vehículos marcados como recuperados",
              Icons.check_circle,
              Colors.greenAccent,
              recoveredVehiclesStream,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminRecoveredVehiclesScreen(),
                ),
              ),
            ),

            _simpleCard(
              context,
              "Vehículos externos",
              "Vehículos autorizados desde Facebook, WhatsApp y otras fuentes",
              Icons.add_road,
              Colors.cyanAccent,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminExternalVehiclesScreen(),
                ),
              ),
            ),

            _simpleCard(
              context,
              "Riesgo legal",
              "Usuarios o casos que requieren revisión especial",
              Icons.gavel,
              Colors.deepOrange,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminLegalRiskUsersScreen(),
                ),
              ),
            ),

            _simpleCard(
              context,
              "Re-verificación usuarios",
              "Usuarios que deben confirmar identidad nuevamente",
              Icons.verified_user,
              Colors.orangeAccent,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminReverificationUsersScreen(),
                ),
              ),
            ),

            _simpleCard(
              context,
              "Salir modo admin",
              "Volver a la pantalla principal de SKANO",
              Icons.logout,
              Colors.grey,
              () => Navigator.pushNamedAndRemoveUntil(
                context,
                "/home",
                (_) => false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            neonBlue.withOpacity(0.25),
            Colors.white.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: neonBlue.withOpacity(0.55)),
        boxShadow: [
          BoxShadow(
            color: neonBlue.withOpacity(0.18),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: neonBlue,
            child: Icon(
              Icons.admin_panel_settings,
              color: Colors.black,
              size: 30,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Panel central SKANO",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Revisa usuarios, vehículos, reportes y alertas pendientes desde un solo lugar.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 20,
          decoration: BoxDecoration(
            color: neonBlue,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _statBox(
    String title,
    int count,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.045),
        border: Border.all(color: color.withOpacity(0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _priorityPanel({
    required int pendingVehicles,
    required int pendingReports,
    required int companyRequests,
  }) {
    final total = pendingVehicles + pendingReports + companyRequests;

    Color color;
    String message;
    IconData icon;

    if (total == 0) {
      color = Colors.greenAccent;
      icon = Icons.check_circle;
      message = "No tienes pendientes críticos en este momento.";
    } else if (total <= 3) {
      color = Colors.orangeAccent;
      icon = Icons.notifications_active;
      message = "Tienes algunos pendientes por revisar.";
    } else {
      color = Colors.redAccent;
      icon = Icons.priority_high;
      message = "Atención: tienes varios pendientes acumulados.";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.75)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color,
            child: Icon(icon, color: Colors.black),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            total.toString(),
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    Stream<QuerySnapshot> stream,
    VoidCallback onTap,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (_, snap) {
        final count = snap.hasData ? snap.data!.docs.length : 0;
        return _baseCard(context, title, subtitle, icon, color, count, onTap);
      },
    );
  }

  Widget _simpleCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return _baseCard(context, title, subtitle, icon, color, null, onTap);
  }

  Widget _baseCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    int? count,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 13),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.65)),
          borderRadius: BorderRadius.circular(18),
          color: Colors.white.withOpacity(0.035),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.16),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.45)),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (count != null)
              Container(
                constraints: const BoxConstraints(minWidth: 42),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  count.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              Icon(
                Icons.chevron_right,
                color: color,
              ),
          ],
        ),
      ),
    );
  }
} 