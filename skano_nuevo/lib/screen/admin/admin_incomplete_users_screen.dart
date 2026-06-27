import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

class AdminIncompleteUsersScreen extends StatefulWidget {
  const AdminIncompleteUsersScreen({super.key});

  @override
  State<AdminIncompleteUsersScreen> createState() =>
      _AdminIncompleteUsersScreenState();
}

class _AdminIncompleteUsersScreenState
    extends State<AdminIncompleteUsersScreen> {
  static const Color _bg = Color(0xFF07091F);
  static const Color _card = Color(0xFF101735);
  static const Color _neonBlue = Color(0xFF0A6CFF);

  bool _syncingEmails = false;

  bool _auditing = false;

Future<void> _auditAuthVsUsers() async {
  try {
    setState(() => _auditing = true);

    final result = await FirebaseFunctions.instance
        .httpsCallable('auditAuthVsUsers')
        .call();

    final data = result.data as Map?;

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.blue,
        content: Text(
          'Auth: ${data?['authCount'] ?? 0} | '
          'Users: ${data?['usersFound'] ?? 0} | '
          'Faltantes: ${data?['missingUsers'] ?? 0}',
        ),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text('Error auditoría: $e'),
      ),
    );
  } finally {
    if (mounted) {
      setState(() => _auditing = false);
    }
  }
}

  Future<void> _syncEmailIndex() async {
    try {
      setState(() => _syncingEmails = true);

      final result = await FirebaseFunctions.instance
          .httpsCallable('importEmailIndexFromAuth')
          .call();

      final data = result.data as Map?;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
              'Revisados: ${data?['checked'] ?? 0} | '
              'Importados: ${data?['createdOrUpdated'] ?? 0} | '
              'Sin correo: ${data?['skippedWithoutEmail'] ?? 0}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Error al importar correos: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _syncingEmails = false);
      }
    }
  }

  Future<void> _markEmailSent(String uid) async {
    await FirebaseFirestore.instance
        .collection('incomplete_users')
        .doc(uid)
        .set({
      'email_sent': true,
      'email_sent_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Usuario marcado como correo enviado.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _deleteIncompleteUser(String uid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        title: const Text(
          'Eliminar registro',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Esto solo elimina al usuario de la lista de incompletos. No elimina su cuenta principal.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseFirestore.instance
        .collection('incomplete_users')
        .doc(uid)
        .delete();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Registro eliminado de usuarios incompletos.'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'Sin dato';

    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    }

    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('incomplete_users')
        .orderBy('imported_at', descending: true);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      title: const Text(
    'Usuarios incompletos',
    style: TextStyle(fontWeight: FontWeight.bold),
  ),
  actions: [
    IconButton(
      tooltip: 'Importar correos Authentication',
      onPressed: _syncingEmails ? null : _syncEmailIndex,
      icon: _syncingEmails
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.alternate_email),
    ),

    IconButton(
      tooltip: 'Auditar Authentication vs Users',
      onPressed: _auditing ? null : _auditAuthVsUsers,
      icon: _auditing
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.manage_search),
    ),
  ],
),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorState(error: snapshot.error.toString());
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: _neonBlue),
            );
          }

          final docs = snapshot.data!.docs;

          final emailSent =
              docs.where((d) => d.data()['email_sent'] == true).length;

          final pendingEmail =
              docs.where((d) => d.data()['email_sent'] != true).length;

          return Column(
            children: [
              _HeaderCard(
                total: docs.length,
                emailSent: emailSent,
                pendingEmail: pendingEmail,
                syncingEmails: _syncingEmails,
                onSyncEmails: _syncEmailIndex,
              ),
              Expanded(
                child: docs.isEmpty
                    ? const _EmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data();
                          final uid = doc.id;

                          final email =
                              (data['email'] ?? 'Sin correo').toString();
                          final reason =
                              (data['reason'] ?? 'Sin motivo').toString();
                          final source =
                              (data['source'] ?? 'Sin origen').toString();
                          final emailSent = data['email_sent'] == true;
                          final createdAt = _formatValue(data['createdAt']);
                          final lastSignIn =
                              _formatValue(data['lastSignInTime']);
                          final importedAt = _formatValue(data['imported_at']);

                          return _IncompleteUserCard(
                            uid: uid,
                            email: email,
                            reason: reason,
                            source: source,
                            createdAt: createdAt,
                            lastSignIn: lastSignIn,
                            importedAt: importedAt,
                            emailSent: emailSent,
                            onMarkEmailSent: () => _markEmailSent(uid),
                            onDelete: () => _deleteIncompleteUser(uid),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final int total;
  final int emailSent;
  final int pendingEmail;
  final bool syncingEmails;
  final VoidCallback onSyncEmails;

  const _HeaderCard({
    required this.total,
    required this.emailSent,
    required this.pendingEmail,
    required this.syncingEmails,
    required this.onSyncEmails,
  });

  static const Color _neonBlue = Color(0xFF0A6CFF);

  @override
  Widget build(BuildContext context) {
    Color alertColor;
    String alertText;
    IconData alertIcon;

    if (total == 0) {
      alertColor = Colors.greenAccent;
      alertIcon = Icons.check_circle;
      alertText = 'No hay usuarios incompletos por gestionar.';
    } else if (pendingEmail == 0) {
      alertColor = Colors.greenAccent;
      alertIcon = Icons.mark_email_read;
      alertText = 'Todos los usuarios incompletos ya fueron contactados.';
    } else {
      alertColor = Colors.orangeAccent;
      alertIcon = Icons.warning_amber_rounded;
      alertText = 'Hay usuarios incompletos pendientes de contactar.';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            _neonBlue.withOpacity(0.24),
            Colors.white.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: _neonBlue.withOpacity(0.55)),
        boxShadow: [
          BoxShadow(
            color: _neonBlue.withOpacity(0.14),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: _neonBlue,
                child: Icon(
                  Icons.mark_email_unread,
                  color: Colors.black,
                  size: 28,
                ),
              ),
              SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recuperación de usuarios',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Personas que crearon cuenta, pero no completaron el flujo de verificación.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: alertColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: alertColor.withOpacity(0.55)),
            ),
            child: Row(
              children: [
                Icon(alertIcon, color: alertColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    alertText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  label: 'Total',
                  value: total.toString(),
                  icon: Icons.people_alt,
                  color: Colors.lightBlueAccent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatBox(
                  label: 'Correo enviado',
                  value: emailSent.toString(),
                  icon: Icons.mark_email_read,
                  color: Colors.greenAccent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatBox(
                  label: 'Pendientes',
                  value: pendingEmail.toString(),
                  icon: Icons.mail_outline,
                  color: Colors.orangeAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: syncingEmails ? null : onSyncEmails,
              icon: syncingEmails
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.alternate_email),
              label: Text(
                syncingEmails
                    ? 'Importando correos registrados...'
                    : 'Importar correos registrados desde Authentication',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _neonBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IncompleteUserCard extends StatelessWidget {
  final String uid;
  final String email;
  final String reason;
  final String source;
  final String createdAt;
  final String lastSignIn;
  final String importedAt;
  final bool emailSent;
  final VoidCallback onMarkEmailSent;
  final VoidCallback onDelete;

  const _IncompleteUserCard({
    required this.uid,
    required this.email,
    required this.reason,
    required this.source,
    required this.createdAt,
    required this.lastSignIn,
    required this.importedAt,
    required this.emailSent,
    required this.onMarkEmailSent,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = emailSent ? Colors.greenAccent : Colors.orangeAccent;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101735),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.45)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(0.18),
              child: Icon(
                emailSent ? Icons.mark_email_read : Icons.mark_email_unread,
                color: color,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    email,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  _StatusBadge(
                    text: emailSent
                        ? 'Correo de recuperación enviado'
                        : 'Pendiente de contactar',
                    color: color,
                  ),
                  const SizedBox(height: 12),
                  _InfoLine(label: 'UID', value: uid),
                  _InfoLine(label: 'Motivo', value: reason),
                  _InfoLine(label: 'Origen', value: source),
                  _InfoLine(label: 'Creado', value: createdAt),
                  _InfoLine(label: 'Último ingreso', value: lastSignIn),
                  _InfoLine(label: 'Importado', value: importedAt),
                ],
              ),
            ),
            PopupMenuButton<String>(
              color: const Color(0xFF101735),
              iconColor: Colors.white,
              onSelected: (value) {
                if (value == 'email_sent') {
                  onMarkEmailSent();
                }

                if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'email_sent',
                  child: Text(
                    'Marcar correo enviado',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Eliminar de incompletos',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusBadge({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12.5,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF07091F).withOpacity(0.88),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(22),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF101735),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.greenAccent.withOpacity(0.45)),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.greenAccent,
              size: 44,
            ),
            SizedBox(height: 12),
            Text(
              'No hay usuarios incompletos',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Por ahora no existen registros pendientes en esta sección.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;

  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(22),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF101735),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.redAccent.withOpacity(0.55)),
        ),
        child: Text(
          'Error cargando usuarios incompletos:\n$error',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}