//============================================================================
// 📄 Archivo: main.dart
// ✅ COMPILABLE con tu proyecto actual
//============================================================================

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

// BUILD_MARK: 2026-04-17_report_selfie_admin_bank
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

// Navigator key
import 'app_navigator.dart';

// ================= RESPONSIBLE ACCESS =================
import 'screen/responsible_access_gate.dart';

// ================= BASE / AUTH =================
import 'screen/start_gate_screen.dart';
import 'screen/welcome_screen.dart';
import 'screen/login_screen.dart';
import 'screen/register_screen.dart';
import 'screen/forgot_password_screen.dart';
import 'screen/home_screen.dart';
import 'screen/terms_accept_screen.dart';
import 'screen/verify_email_screen.dart';

// ================= PROFILE =================
import 'screen/edit_profile_screen.dart';
import 'screen/my_account_screen.dart';
import 'screen/change_pin_screen.dart';

// ================= DOCUMENTOS / IDENTIDAD =================
import 'screen/document_upload_screen.dart';
import 'screen/selfie_register_screen.dart';
import 'screen/session_verification_screen.dart';
import 'screen/account_blocked_screen.dart';

// ================= VEHÍCULOS =================
import 'screen/drawer/add_vehicle_step1_screen.dart';
import 'screen/drawer/add_vehicle_step4_screen.dart';
import 'screen/my_vehicles_screen.dart';
import 'screen/vehicle_detail_screen.dart';

// ================= MAPA =================
import 'screen/alert_map_screen.dart';

// ================= REPORTES =================
import 'screen/report_form_screen.dart';
import 'screen/report_result_screen.dart';
import 'screen/report_declaration_screen.dart';
import 'screen/report_protocol.dart';
import 'screen/report_send_screen.dart';
import 'screen/report_waiting_authority_screen.dart';
import 'screen/report_selfie_screen.dart';

// ================= OCR =================
import 'screen/plate_scanner_screen.dart';

// ================= DRAWER =================
import 'screen/drawer/terms_screen.dart';
import 'screen/drawer/how_it_works_screen.dart';
import 'screen/drawer/emergency_screen.dart';
import 'screen/drawer/stats_screen.dart';
import 'screen/drawer/my_reports_screen.dart';
import 'screen/drawer/invite_friends_screen.dart';
import 'screen/drawer/earnings_screen.dart';

// ================= MEMBERSHIP =================
import 'screen/drawer/plans_screen.dart';
import 'screen/my_membership_screen.dart';
import 'screen/membership_terms_screen.dart';

// ================= PAYMENTS =================
import 'screen/external_payment_screen.dart';
import 'screen/pay_membership_screen.dart';

// ================= BANK =================
import 'screen/bank_account_screen.dart';

// ================= ADMIN =================
import 'screen/admin/admin_dashboard_screen.dart';
import 'screen/admin/admin_reports_screen.dart';
import 'screen/admin/admin_review_report_screen.dart';
import 'screen/admin/admin_users_screen.dart';
import 'screen/admin/admin_review_user_screen.dart';
import 'screen/admin/admin_review_users_screen.dart';
import 'screen/admin/admin_vehicles_screen.dart';
import 'screen/admin/admin_review_vehicle_screen.dart';
import 'screen/admin/admin_incomplete_users_screen.dart';
import 'screen/admin/admin_stolen_vehicles_screen.dart';
import 'screen/admin/admin_recovered_vehicles_screen.dart';
import 'screen/admin/admin_legal_risk_users_screen.dart';
import 'screen/admin/admin_blocked_users_screen.dart';
import 'screen/admin/admin_company_requests_screen.dart';

// ✅ NUEVO ADMIN BANK
import 'screen/admin/admin_bank_verification_screen.dart';
import 'screen/admin/admin_review_bank_verification_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint("=== RUNNING BUILD_MARK: 2026-04-17_report_selfie_admin_bank ===");

  if (!kIsWeb && Platform.isAndroid) {
    final GoogleMapsFlutterAndroid mapsImplementation =
        GoogleMapsFlutterAndroid();
    mapsImplementation.useAndroidViewSurface = true;
  }

  final isWindows = !kIsWeb && Platform.isWindows;

  if (!isWindows) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(SkanoApp(isWindows: isWindows));
}

// ======================================================
// 🟦 APP ROOT
// ======================================================
class SkanoApp extends StatelessWidget {
  final bool isWindows;
  const SkanoApp({super.key, required this.isWindows});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: skanoNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'SKANO',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: const Color(0xFF0A6CFF),
      ),
      builder: (context, child) {
        final safeChild = child ?? const SizedBox.shrink();
        if (isWindows) return safeChild;

        return ResponsibleAccessGate(
          navigatorKey: skanoNavigatorKey,
          idleMinutes: 30,
          child: safeChild,
        );
      },
      home: isWindows ? const _WindowsPlaceholder() : const AuthGate(),

      routes: {
        '/welcome': (_) => const WelcomeScreen(),
        '/welcome/': (_) => const WelcomeScreen(),

        '/login': (_) => LoginScreen(),
        '/login/': (_) => LoginScreen(),

        '/register': (_) => const RegisterScreen(),
        '/register/': (_) => const RegisterScreen(),

        '/forgot_password': (_) => const ForgotPasswordScreen(),
        '/forgot_password/': (_) => const ForgotPasswordScreen(),

        '/start_gate': (_) => const StartGateScreen(),
        '/start_gate/': (_) => const StartGateScreen(),

        '/verify_email': (_) => const VerifyEmailScreen(),
        '/verify_email/': (_) => const VerifyEmailScreen(),

        '/terms_accept': (_) => const TermsAcceptScreen(),
        '/terms_accept/': (_) => const TermsAcceptScreen(),

        '/home': (_) => const HomeScreen(),
        '/home/': (_) => const HomeScreen(),

        '/edit_profile': (_) => const EditProfileScreen(),
        '/edit_profile/': (_) => const EditProfileScreen(),

        '/my_account': (_) => MyAccountScreen(),
        '/my_account/': (_) => MyAccountScreen(),

        '/change_pin': (_) => const ChangePinScreen(),
        '/change_pin/': (_) => const ChangePinScreen(),

        '/document_upload': (_) => const DocumentUploadScreen(),
        '/document_upload/': (_) => const DocumentUploadScreen(),

        '/selfie_register': (_) => const SelfieRegisterScreen(),
        '/selfie_register/': (_) => const SelfieRegisterScreen(),

        '/session_verification': (_) => const SessionVerificationScreen(),
        '/session_verification/': (_) => const SessionVerificationScreen(),

        '/add_vehicle': (_) => const AddVehicleStep1Screen(),
        '/add_vehicle/': (_) => const AddVehicleStep1Screen(),

        '/add_vehicle_step4': (_) => const AddVehicleStep4Screen(),
        '/add_vehicle_step4/': (_) => const AddVehicleStep4Screen(),

        '/my_vehicles': (_) => const MyVehiclesScreen(),
        '/my_vehicles/': (_) => const MyVehiclesScreen(),

        '/vehicle_detail': (_) => const VehicleDetailScreen(),
        '/vehicle_detail/': (_) => const VehicleDetailScreen(),

        '/alert_map': (_) => const AlertMapScreen(),
        '/alert_map/': (_) => const AlertMapScreen(),

        '/report': (_) => ReportFormScreen(),
        '/report/': (_) => ReportFormScreen(),

        '/report_result': (_) => const ReportResultScreen(),
        '/report_result/': (_) => const ReportResultScreen(),

        '/report_declaration': (_) => const ReportDeclarationScreen(),
        '/report_declaration/': (_) => const ReportDeclarationScreen(),

        '/report_protocol': (_) => const ReportProtocol(),
        '/report_protocol/': (_) => const ReportProtocol(),

        '/report_send': (_) => const ReportSendScreen(),
        '/report_send/': (_) => const ReportSendScreen(),

        '/plate_scanner': (_) => const PlateScannerScreen(),
        '/plate_scanner/': (_) => const PlateScannerScreen(),

        '/how_it_works': (_) => const HowItWorksScreen(),
        '/how_it_works/': (_) => const HowItWorksScreen(),

        '/emergency': (_) => const EmergencyScreen(),
        '/emergency/': (_) => const EmergencyScreen(),

        '/stats': (_) => const StatsScreen(),
        '/stats/': (_) => const StatsScreen(),

        '/my_reports': (_) => const MyReportsScreen(),
        '/my_reports/': (_) => const MyReportsScreen(),

        '/invite_friends': (_) => const InviteFriendsScreen(),
        '/invite_friends/': (_) => const InviteFriendsScreen(),

        '/terms': (_) => const TermsScreen(),
        '/terms/': (_) => const TermsScreen(),

        '/earnings': (_) => const EarningsScreen(),
        '/earnings/': (_) => const EarningsScreen(),

        '/plans': (_) => const PlansScreen(),
        '/plans/': (_) => const PlansScreen(),

        '/my_membership': (_) => const MyMembershipScreen(),
        '/my_membership/': (_) => const MyMembershipScreen(),

        '/membership_terms': (_) => const MembershipTermsScreen(),
        '/membership_terms/': (_) => const MembershipTermsScreen(),

        '/external_payment': (_) => const ExternalPaymentScreen(),
        '/external_payment/': (_) => const ExternalPaymentScreen(),

        '/pay_membership': (_) => const PayMembershipScreen(),
        '/pay_membership/': (_) => const PayMembershipScreen(),

        '/bank_account': (_) => const BankAccountScreen(),
        '/bank_account/': (_) => const BankAccountScreen(),

        // ===== ADMIN =====
        '/admin_dashboard': (_) => AdminGate(child: AdminDashboardScreen()),
        '/admin_dashboard/': (_) => AdminGate(child: AdminDashboardScreen()),

        '/admin_users': (_) => AdminGate(child: AdminUsersScreen()),
        '/admin_users/': (_) => AdminGate(child: AdminUsersScreen()),

        '/admin_review_users': (_) => AdminGate(child: AdminReviewUsersScreen()),
        '/admin_review_users/': (_) =>
            AdminGate(child: AdminReviewUsersScreen()),

        '/admin_reports': (_) => AdminGate(child: AdminReportsScreen()),
        '/admin_reports/': (_) => AdminGate(child: AdminReportsScreen()),

        '/admin_vehicles': (_) => AdminGate(child: AdminVehiclesScreen()),
        '/admin_vehicles/': (_) => AdminGate(child: AdminVehiclesScreen()),

        '/admin_stolen_vehicles': (_) =>
            AdminGate(child: AdminStolenVehiclesScreen()),
        '/admin_stolen_vehicles/': (_) =>
            AdminGate(child: AdminStolenVehiclesScreen()),

        '/admin_recovered_vehicles': (_) =>
            AdminGate(child: AdminRecoveredVehiclesScreen()),
        '/admin_recovered_vehicles/': (_) =>
            AdminGate(child: AdminRecoveredVehiclesScreen()),

        '/admin_legal_risk_users': (_) =>
            AdminGate(child: AdminLegalRiskUsersScreen()),
        '/admin_legal_risk_users/': (_) =>
            AdminGate(child: AdminLegalRiskUsersScreen()),

        '/admin_blocked_users': (_) =>
            AdminGate(child: AdminBlockedUsersScreen()),
        '/admin_blocked_users/': (_) =>
            AdminGate(child: AdminBlockedUsersScreen()),

        '/admin_company_requests': (_) =>
            AdminGate(child: AdminCompanyRequestsScreen()),
        '/admin_company_requests/': (_) =>
            AdminGate(child: AdminCompanyRequestsScreen()),

        '/admin_bank_verifications': (_) =>
            AdminGate(child: AdminReviewBankVerificationScreen(userId: "test")),
        '/admin_bank_verifications/': (_) =>
            AdminGate(child: AdminReviewBankVerificationScreen(userId: "test")),
      },

      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/report_selfie':
          case '/report_selfie/': {
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            final nextRoute =
                (args['nextRoute'] ?? '/report_declaration').toString();
            final reportDraftRaw = args['reportDraft'];
            final Map<String, dynamic>? reportDraft =
                reportDraftRaw is Map<String, dynamic>
                    ? reportDraftRaw
                    : args;

            return MaterialPageRoute(
              builder: (_) => ReportSelfieScreen(
                nextRoute: nextRoute,
                reportDraft: reportDraft,
              ),
              settings: settings,
            );
          }

          case '/account_blocked':
          case '/account_blocked/': {
            final args = settings.arguments as Map<String, dynamic>?;
            final reason = (args?['reason'] ?? '').toString();

            return MaterialPageRoute(
              builder: (_) => AccountBlockedScreen(
                reason: reason,
                blockedUntil: args?['blockedUntil'],
                adminComment: args?['adminComment'],
              ),
              settings: settings,
            );
          }

          case '/report_waiting_authority':
          case '/report_waiting_authority/': {
            final args = settings.arguments as Map<String, dynamic>?;
            final reportId = (args?['reportId'] ?? '').toString();

            if (reportId.isEmpty) {
              return _errorRoute("Falta reportId para /report_waiting_authority");
            }

            return MaterialPageRoute(
              builder: (_) => ReportWaitingAuthorityScreen(reportId: reportId),
              settings: settings,
            );
          }

          case '/admin_review_user':
          case '/admin_review_user/': {
            final args = settings.arguments as Map<String, dynamic>?;
            final userId = args?['userId']?.toString();

            if (userId == null || userId.isEmpty) {
              return _errorRoute("Falta userId para /admin_review_user");
            }

            return MaterialPageRoute(
              builder: (_) =>
                  AdminGate(child: AdminReviewUserScreen(userId: userId)),
              settings: settings,
            );
          }

          case '/admin_review_report':
          case '/admin_review_report/': {
            final args = settings.arguments as Map<String, dynamic>?;
            final reportId = args?['reportId']?.toString();

            if (reportId == null || reportId.isEmpty) {
              return _errorRoute("Falta reportId para /admin_review_report");
            }

            return MaterialPageRoute(
              builder: (_) =>
                  AdminGate(child: AdminReviewReportScreen(reportId: reportId)),
              settings: settings,
            );
          }

          case '/admin_review_vehicle':
          case '/admin_review_vehicle/': {
            final args = settings.arguments as Map<String, dynamic>?;
            final vehicleId = args?['vehicleId']?.toString();

            if (vehicleId == null || vehicleId.isEmpty) {
              return _errorRoute("Falta vehicleId para /admin_review_vehicle");
            }

            return MaterialPageRoute(
              builder: (_) => AdminGate(
                child: AdminReviewVehicleScreen(vehicleId: vehicleId),
              ),
              settings: settings,
            );
          }

          // ✅ NUEVO ADMIN REVIEW BANK
          case '/admin_review_bank_verification':
          case '/admin_review_bank_verification/': {
            final args = settings.arguments as Map<String, dynamic>?;
            final userId = args?['userId']?.toString();

            if (userId == null || userId.isEmpty) {
              return _errorRoute(
                "Falta userId para /admin_review_bank_verification",
              );
            }

            return MaterialPageRoute(
              builder: (_) => AdminGate(
                child: AdminReviewBankVerificationScreen(userId: userId),
              ),
              settings: settings,
            );
          }

          default:
            return null;
        }
      },

      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (_) => const HomeScreen(),
        settings: settings,
      ),
    );
  }

  static Route _errorRoute(String msg) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text("SKANO"),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ),
      ),
    );
  }
}

// ======================================================
// 🔐 AUTH GATE
// ======================================================
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData) return const WelcomeScreen();
        return const StartGateScreen();
      },
    );
  }
}

// ======================================================
// 🔐 ADMIN GATE
// ======================================================
class AdminGate extends StatelessWidget {
  final Widget child;
  const AdminGate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const WelcomeScreen();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = (snap.data!.data() as Map<String, dynamic>?) ?? {};
        if (data['role'] != 'admin') return const HomeScreen();
        return child;
      },
    );
  }
}

// ======================================================
// 🪟 PLACEHOLDER WINDOWS
// ======================================================
class _WindowsPlaceholder extends StatelessWidget {
  const _WindowsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          'SKANO\n\nModo Windows (UI Test)',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
    );
  }
}