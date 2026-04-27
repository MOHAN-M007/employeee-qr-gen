import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/glass_panel.dart';
import 'employee_form_screen.dart';
import 'history_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatelessWidget {
  final String userRole;

  const DashboardScreen({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    final role = userRole.trim().toLowerCase();
    final isAdmin = role == "admin";

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? "Dashboard (Admin)" : "Dashboard (User)"),
        actions: [
          IconButton(
            tooltip: "Logout",
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.logout();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.10),
                Colors.white,
                Theme.of(context).colorScheme.primary.withOpacity(0.06),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlassPanel(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Icon(
                        isAdmin ? Icons.verified_user : Icons.person,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Signed in as ${isAdmin ? "Admin" : "User"}",
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GlassPanel(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => HistoryScreen(userRole: role),
                              ),
                            );
                          },
                          child: const Text("View Employees"),
                        ),
                      ),
                      if (isAdmin) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const EmployeeFormScreen(),
                                ),
                              );
                            },
                            child: const Text("Add Employee"),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
