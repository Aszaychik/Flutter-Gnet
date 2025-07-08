import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';
import '../constants/colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await StorageService.getUser();
    if (userData != null) {
      setState(() {
        _user = User.fromJson(userData);
        _isLoading = false;
      });
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _logout() async {
    await StorageService.clearAuthData();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  // Profile Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _user!.name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.onBackground,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _user!.email,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // User Information Section
            _buildSectionHeader('Account Information'),
            _buildInfoCard(
              context,
              title: 'Username',
              value: _user!.username,
              icon: Icons.person_outline,
            ),
            _buildInfoCard(
              context,
              title: 'Role',
              value: _user!.role,
              icon: Icons.work_outline,
            ),
            const SizedBox(height: 32),

            // Financial Information Section
            _buildSectionHeader('Financial Status'),
            _buildFinancialCard(
              context,
              title: 'Current Balance',
              value: _user!.balance,
              isPositive: true,
            ),
            _buildFinancialCard(
              context,
              title: 'Current Debt',
              value: _user!.debt,
              isPositive: false,
            ),
            _buildFinancialCard(
              context,
              title: 'Credit Limit',
              value: _user!.maxDebt,
              isPositive: null,
            ),
            const SizedBox(height: 40),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error.withOpacity(0.1),
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, {required String title, required String value, required IconData icon}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        subtitle: Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialCard(BuildContext context, {required String title, required int value, required bool? isPositive}) {
    final Color valueColor = isPositive == null
        ? AppColors.onBackground
        : isPositive
        ? Colors.green
        : Colors.red;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              'Rp${_formatCurrency(value)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  String _formatDate(String date) {
    final dateTime = DateTime.tryParse(date) ?? DateTime.now();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}