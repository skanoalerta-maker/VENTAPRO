import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// =======================================================
/// SKANO DRAWER
/// Menú lateral principal de la aplicación
/// - Carga datos del usuario
/// - Navega a las secciones principales
/// - Maneja cierre de sesión
/// =======================================================

class SkanoDrawer extends StatelessWidget {
  /// Nombre del usuario mostrado en el header
  final String userName;

  /// Métricas (pueden usarse para badges / stats)
  final int correctReports;
  final int totalReports;

  const SkanoDrawer({
    super.key,
    required this.userName,
    required this.correctReports,
    required this.totalReports,
  });

  /// ===================================================
  /// CARGA DATOS DEL USUARIO DESDE FIRESTORE
  /// Se usa para:
  /// - Foto de perfil (faceUrl)
  /// - Flags futuras (bank_verified, role, etc.)
  /// ===================================================
  Future<Map<String, dynamic>> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc =
        await FirebaseFirestore.instance.collection("users").doc(uid).get();
    return doc.data() ?? {};
  }

  /// ===================================================
  /// CERRAR SESIÓN
  /// - Cierra FirebaseAuth
  /// - Limpia navegación
  /// - Redirige a StartGate
  /// ===================================================
  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      "/start_gate",
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color neonBlue = Color(0xFF0A6CFF);

    return Drawer(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _loadUserData(),
          builder: (context, snapshot) {
            final data = snapshot.data ?? {};
            final String? faceUrl = data["faceUrl"];

            return Column(
              children: [
                // ===================================================
                // HEADER DEL DRAWER
                // Muestra:
                // - Foto de rostro (selfie verificada)
                // - Nombre del usuario
                // ===================================================
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 22, 16, 22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0A6CFF), Color(0xFF7C4DFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: neonBlue.withOpacity(0.35),
                        blurRadius: 20,
                        spreadRadius: 1,
                      )
                    ],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(22),
                      bottomRight: Radius.circular(22),
                    ),
                  ),
                  child: Row(
                    children: [
                      // FOTO PERFIL
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white, width: 2),
                        ),
                        child: CircleAvatar(
                          backgroundColor: Colors.black,
                          backgroundImage:
                              faceUrl != null && faceUrl.isNotEmpty
                                  ? NetworkImage(faceUrl)
                                  : null,
                          child: faceUrl == null || faceUrl.isEmpty
                              ? const Icon(Icons.person,
                                  color: Colors.white, size: 30)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // NOMBRE USUARIO
                      Expanded(
                        child: Text(
                          userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ===================================================
                // LISTA DE OPCIONES DEL DRAWER
                // ===================================================
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // ================= ACTIVIDAD =================
                      const _SectionTitle("Tu actividad"),

                      /// GANANCIAS / PAGOS
                      /// -> EarningsScreen
                      _DrawerItem(
                        icon: Icons.account_balance_wallet_outlined,
                        iconColor: Color(0xFF4CAF50),
                        title: "Ganancias y pagos",
                        subtitle: "Tu saldo acumulado",
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, "/earnings");
                        },
                      ),

                      /// 🔵 DATOS BANCARIOS (NUEVO)
                      /// -> BankAccountScreen
                      /// Permite:
                      /// - Ingresar banco
                      /// - Subir cartola
                      /// - Confirmar con PIN
                      _DrawerItem(
                        icon: Icons.account_balance_outlined,
                        iconColor: Color(0xFF81C784),
                        title: "Datos bancarios",
                        subtitle: "Cuenta para recibir recompensas",
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, "/bank_account");
                        },
                      ),

                      /// NIVELES / RANGOS
                      /// -> StatsScreen
                      _DrawerItem(
                        icon: Icons.emoji_events_outlined,
                        iconColor: Color(0xFFFFC107),
                        title: "Premios y niveles",
                        subtitle: "Revisa tus rangos SKANO",
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, "/stats");
                        },
                      ),

                      /// HISTORIAL REPORTES
                      /// -> MyReportsScreen
                      _DrawerItem(
                        icon: Icons.history,
                        iconColor: Color(0xFF42A5F5),
                        title: "Historial de reportes",
                        subtitle: "Todos tus reportes enviados",
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, "/my_reports");
                        },
                      ),

                      const SizedBox(height: 16),

                      // ================= SEGURIDAD =================
                      const _SectionTitle("Tu seguridad"),

                      /// VEHÍCULOS
                      /// -> MyVehiclesScreen
                      _DrawerItem(
                        icon: Icons.directions_car_filled_outlined,
                        iconColor: Color(0xFFEF5350),
                        title: "Mis vehículos registrados",
                        subtitle: "Ver / agregar vehículos",
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, "/my_vehicles");
                        },
                      ),

                      /// CÓMO ACTUAR
                      /// -> HowItWorksScreen
                      _DrawerItem(
                        icon: Icons.policy_outlined,
                        iconColor: Color(0xFFAB47BC),
                        title: "Acciones al encontrar un vehículo",
                        subtitle: "Guía con Carabineros y PDI",
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, "/how_it_works");
                        },
                      ),

                      /// EMERGENCIA
                      /// -> EmergencyScreen
                      _DrawerItem(
                        icon: Icons.emergency_share_outlined,
                        iconColor: Color(0xFFFF7043),
                        title: "Emergencia 133",
                        subtitle: "Contacto inmediato",
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, "/emergency");
                        },
                      ),

                      const SizedBox(height: 16),

                      // ================= PERFIL =================
                      const _SectionTitle("Mi perfil"),

                      /// MI CUENTA
                      /// -> MyAccountScreen
                      _DrawerItem(
                        icon: Icons.person_outline,
                        iconColor: Color(0xFF64B5F6),
                        title: "Mi Cuenta",
                        subtitle: "Datos • Verificación",
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, "/my_account");
                        },
                      ),

                      /// MEMBRESÍA
                      /// -> MyMembershipScreen
                      _DrawerItem(
                        icon: Icons.workspace_premium_outlined,
                        iconColor: Color(0xFFFFD54F),
                        title: "Mi Membresía",
                        subtitle: "Estado • Plan • Renovar",
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, "/my_membership");
                        },
                      ),

                      /// INVITAR AMIGOS
                      /// -> InviteFriendsScreen
                      _DrawerItem(
                        icon: Icons.group_add_outlined,
                        iconColor: Color(0xFF26C6DA),
                        title: "Invitar amigos",
                        subtitle: "Gana recompensas por invitar",
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, "/invite_friends");
                        },
                      ),

                      /// TÉRMINOS
                      /// -> TermsScreen
                      _DrawerItem(
                        icon: Icons.description_outlined,
                        iconColor: Color(0xFF90CAF9),
                        title: "Términos y condiciones",
                        subtitle: "Condiciones de uso de SKANO",
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, "/terms");
                        },
                      ),

                      const Divider(color: Colors.white24, height: 32),

                      // ================= LOGOUT =================
                      _DrawerItem(
                        icon: Icons.logout,
                        iconColor: Colors.redAccent,
                        title: "Salir de mi cuenta",
                        subtitle: "Cerrar sesión y usar otra cuenta",
                        onTap: () async {
                          Navigator.pop(context);
                          await _logout(context);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// =======================================================
/// COMPONENTES AUXILIARES
/// =======================================================

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.18),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.white.withOpacity(0.6),
          fontSize: 11,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.white.withOpacity(0.5),
      ),
      onTap: onTap,
    );
  }
}
