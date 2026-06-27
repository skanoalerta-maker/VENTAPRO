import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool darkMode = true;
  String selectedLanguage = "Español";
  String appVersion = "Cargando...";
  String buildNumber = "...";

  @override
  void initState() {
    super.initState();
    loadAppVersion();
  }

  Future<void> loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      appVersion = info.version;
      buildNumber = info.buildNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text("Configuración"),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
        children: [

          // ---------------- MI CUENTA ----------------
          _section("Mi cuenta"),

          _secureItem(
            icon: Icons.person_outline,
            title: "Editar perfil",
            onVerified: () => Navigator.pushNamed(context, "/edit_profile"),
          ),

          _secureItem(
            icon: Icons.phone_android,
            title: "Cambiar número telefónico",
            onVerified: () => Navigator.pushNamed(context, "/edit_phone"),
          ),

          _secureItem(
            icon: Icons.email_outlined,
            title: "Cambiar correo electrónico",
            onVerified: () => Navigator.pushNamed(context, "/edit_email"),
          ),

          _secureItem(
            icon: Icons.account_balance_outlined,
            title: "Cuenta bancaria / Recompensas",
            onVerified: () => Navigator.pushNamed(context, "/edit_bank"),
          ),

          const SizedBox(height: 28),

          // ---------------- IDIOMA ----------------
          _section("Idioma"),

          _item(
            icon: Icons.language,
            title: "Cambiar idioma",
            trailing: Text(
              selectedLanguage,
              style: const TextStyle(color: Colors.white54),
            ),
            onTap: () => _chooseLanguage(context),
          ),

          const SizedBox(height: 28),

          // ---------------- APARIENCIA ----------------
          _section("Apariencia"),

          SwitchListTile(
            value: darkMode,
            activeColor: const Color(0xFF38BDF8),
            title: const Text("Modo oscuro", style: TextStyle(color: Colors.white)),
            onChanged: (v) {
              setState(() => darkMode = v);
            },
          ),

          const SizedBox(height: 28),

          // ---------------- CENTRO DE CONFIANZA ----------------
          _section("Centro de confianza (Seguridad)"),

          _item(
            icon: Icons.verified_user_outlined,
            title: "Estado de seguridad de la cuenta",
            onTap: () => showDialog(
              context: context,
              builder: (_) => const _DialogTrustCenter(),
            ),
          ),

          _item(
            icon: Icons.face_retouching_natural_outlined,
            title: "Verificación facial obligatoria",
            onTap: () => showDialog(
              context: context,
              builder: (_) => const _DialogFaceVerificationInfo(),
            ),
          ),

          const SizedBox(height: 28),

          // ---------------- VEHÍCULOS ----------------
          _section("Vehículos"),

          _item(
            icon: Icons.directions_car_outlined,
            title: "Mis vehículos",
            onTap: () => Navigator.pushNamed(context, "/vehicle_detail"),
          ),

          _item(
            icon: Icons.add_circle_outline,
            title: "Agregar vehículo",
            onTap: () => Navigator.pushNamed(context, "/add_vehicle"),
          ),

          const SizedBox(height: 28),

          // ---------------- NOTIFICACIONES ----------------
          _section("Notificaciones"),

          _item(
            icon: Icons.notifications_active_outlined,
            title: "Configurar notificaciones",
            onTap: () => showDialog(
              context: context,
              builder: (_) => const _DialogNotificationInfo(),
            ),
          ),

          const SizedBox(height: 28),

          // ---------------- LEGAL ----------------
          _section("Legal y privacidad"),

          _item(
            icon: Icons.article_outlined,
            title: "Términos y condiciones",
            onTap: () => Navigator.pushNamed(context, "/terms"),
          ),

          _item(
            icon: Icons.privacy_tip_outlined,
            title: "Privacidad y antifraude",
            onTap: () => Navigator.pushNamed(context, "/how_it_works"),
          ),

          const SizedBox(height: 28),

          // ---------------- VERSION ----------------
          _section("Información de la app"),

          _item(
            icon: Icons.info_outline,
            title: "Versión de la app",
            trailing: Text(
              "$appVersion ($buildNumber)",
              style: const TextStyle(color: Colors.white54),
            ),
            onTap: () {},
          ),

          const SizedBox(height: 40),

          // ---------------- CERRAR SESIÓN ----------------
          GestureDetector(
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushNamedAndRemoveUntil(context, "/welcome", (_) => false);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  "Cerrar sesión",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- SECCION ----------------
  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
      ),
    );
  }

  // ---------------- ITEM GENERAL ----------------
  Widget _item({
    required IconData icon,
    required String title,
    Widget? trailing,
    required Function() onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0x33222A36),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x22FFFFFF)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle( color: Colors.white, fontSize: 15 ),
              ),
            ),
            trailing ?? const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  // ---------------- ITEM QUE REQUIERE SELFIE ----------------
  Widget _secureItem({
    required IconData icon,
    required String title,
    required Function() onVerified,
  }) {
    return _item(
      icon: icon,
      title: title,
      trailing: const Icon(Icons.lock_outline, color: Colors.white54),
      onTap: () {
        // Antes de editar → selfie obligatoria
        Navigator.pushNamed(context, "/selfie_fast", arguments: {
          "next": onVerified,
        });
      },
    );
  }

  // ---------------- IDIOMAS ----------------
  void _chooseLanguage(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        title: const Text("Seleccionar idioma", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _languageOption("Español"),
            _languageOption("Inglés"),
          ],
        ),
      ),
    );
  }

  Widget _languageOption(String lang) {
    return ListTile(
      title: Text(lang, style: const TextStyle(color: Colors.white)),
      onTap: () {
        setState(() => selectedLanguage = lang);
        Navigator.pop(context);
      },
    );
  }
}

// ---------------- DIALOGOS DE INFORMACIÓN ----------------

class _DialogTrustCenter extends StatelessWidget {
  const _DialogTrustCenter();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1F2E),
      title: const Text("Centro de confianza", style: TextStyle(color: Colors.white)),
      content: const Text(
        "• Reconocimiento facial obligatorio en acciones críticas\n"
        "• Reportes falsos = bloqueo inmediato\n"
        "• Reincidencia = bloqueo permanente\n"
        "• Intentos sospechosos de selfie serán investigados\n"
        "• SKANO protege tu identidad y evita suplantación",
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Entendido", style: TextStyle(color: Colors.blueAccent)),
        )
      ],
    );
  }
}

class _DialogFaceVerificationInfo extends StatelessWidget {
  const _DialogFaceVerificationInfo();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1F2E),
      title: const Text("Verificación facial obligatoria", style: TextStyle(color: Colors.white)),
      content: const Text(
        "Toda acción sensible dentro de SKANO requiere selfie:\n\n"
        "• Editar perfil\n"
        "• Cambiar correo\n"
        "• Cambiar número\n"
        "• Cambiar cuenta bancaria\n"
        "• Reactivar sesión tras 2 horas\n\n"
        "Esto evita suplantación e impide reportes falsos realizados por terceros.",
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("OK", style: TextStyle(color: Colors.blueAccent)),
        )
      ],
    );
  }
}

class _DialogNotificationInfo extends StatelessWidget {
  const _DialogNotificationInfo();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1F2E),
      title: const Text("Notificaciones", style: TextStyle(color: Colors.white)),
      content: const Text(
        "En el futuro podrás configurar:\n\n"
        "• Avistamientos\n"
        "• Emergencias\n"
        "• Documentos vencidos\n"
        "• Seguridad",
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cerrar", style: TextStyle(color: Colors.blueAccent)),
        )
      ],
    );
  }
}
