import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/glowing_button.dart';
import '../../services/admin_service.dart';

/// Admin Panel Screen - App management dashboard with real API
class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Real data from API
  DashboardStats? _stats;
  UsersResponse? _usersResponse;
  List<ReportItem> _reports = [];
  
  bool _isLoadingStats = true;
  bool _isLoadingUsers = true;
  bool _isLoadingReports = true;
  String? _error;
  
  // Search
  final _searchController = TextEditingController();
  String _reportFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadStats(),
      _loadUsers(),
      _loadReports(),
    ]);
  }

  Future<void> _loadStats() async {
    setState(() => _isLoadingStats = true);
    try {
      final adminService = ref.read(adminServiceProvider);
      final stats = await adminService.getStats();
      setState(() {
        _stats = stats;
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingStats = false;
      });
    }
  }

  Future<void> _loadUsers({String? search}) async {
    setState(() => _isLoadingUsers = true);
    try {
      final adminService = ref.read(adminServiceProvider);
      final response = await adminService.getUsers(search: search);
      setState(() {
        _usersResponse = response;
        _isLoadingUsers = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingUsers = false;
      });
    }
  }

  Future<void> _loadReports() async {
    setState(() => _isLoadingReports = true);
    try {
      final adminService = ref.read(adminServiceProvider);
      final reports = await adminService.getReports(
        status: _reportFilter == 'all' ? null : _reportFilter.toUpperCase(),
      );
      setState(() {
        _reports = reports;
        _isLoadingReports = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingReports = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppGradients.button,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text('Admin Panel', style: AppTypography.title2()),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            onPressed: () {
              ref.read(adminServiceProvider).clearToken();
              Navigator.pop(context);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_rounded), text: 'Genel'),
            Tab(icon: Icon(Icons.people_rounded), text: 'Kullanıcılar'),
            Tab(icon: Icon(Icons.report_rounded), text: 'Raporlar'),
            Tab(icon: Icon(Icons.settings_rounded), text: 'Ayarlar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(),
          _buildUsersTab(),
          _buildReportsTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    if (_isLoadingStats) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final stats = _stats;
    if (stats == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text('Veriler yüklenemedi', style: AppTypography.body(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            TextButton(onPressed: _loadStats, child: Text('Tekrar Dene')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStats,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Grid
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.people_rounded,
                    title: 'Toplam Kullanıcı',
                    value: _formatNumber(stats.totalUsers),
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.person_rounded,
                    title: 'Aktif Şu An',
                    value: _formatNumber(stats.onlineUsers),
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.workspace_premium_rounded,
                    title: 'Premium Üyeler',
                    value: _formatNumber(stats.premiumUsers),
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.flag_rounded,
                    title: 'Bekleyen Rapor',
                    value: '${stats.pendingReports}',
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Revenue Section
            Text(
              'GELİR ÖZETİ',
              style: AppTypography.caption1(color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            GlassContainer(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bugün', style: AppTypography.caption1(color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text(
                              '₺${_formatCurrency(stats.todayRevenue)}',
                              style: AppTypography.title1(color: AppColors.success),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 50, color: AppColors.borderSoft),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Bu Ay', style: AppTypography.caption1(color: AppColors.textSecondary)),
                              const SizedBox(height: 4),
                              Text(
                                '₺${_formatCurrency(stats.monthlyRevenue)}',
                                style: AppTypography.title1(color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _RevenueRow(title: 'Premium Abonelikler', amount: stats.premiumRevenue, percentage: 71),
                  _RevenueRow(title: 'Kredi Satışları', amount: stats.creditsRevenue, percentage: 23),
                  _RevenueRow(title: 'Reklam Gelirleri', amount: stats.adsRevenue, percentage: 6),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Quick Actions
            Text('HIZLI İŞLEMLER', style: AppTypography.caption1(color: AppColors.textMuted)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.campaign_rounded,
                    title: 'Duyuru Gönder',
                    color: AppColors.primary,
                    onTap: () => _showAnnouncementDialog(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.card_giftcard_rounded,
                    title: 'Kredi Ver',
                    color: AppColors.warning,
                    onTap: () => _showGiveCreditDialog(),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            style: AppTypography.body(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Kullanıcı ara...',
              hintStyle: AppTypography.body(color: AppColors.textMuted),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search, color: AppColors.primary),
                onPressed: () => _loadUsers(search: _searchController.text),
              ),
              filled: true,
              fillColor: context.colors.surfaceColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (value) => _loadUsers(search: value),
          ),
        ),
        
        if (_isLoadingUsers)
          const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
        else
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadUsers(),
              color: AppColors.primary,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _usersResponse?.users.length ?? 0,
                itemBuilder: (context, index) {
                  final user = _usersResponse!.users[index];
                  return _buildUserCard(user);
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUserCard(UserItem user) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: user.isBanned ? null : AppGradients.button,
              color: user.isBanned ? AppColors.error.withOpacity(0.2) : null,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                user.username.substring(0, 1).toUpperCase(),
                style: AppTypography.title2(color: user.isBanned ? AppColors.error : Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 14),
          
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(user.username, style: AppTypography.headline()),
                    if (user.isPremium) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.verified_rounded, color: AppColors.warning, size: 16),
                    ],
                    if (user.isBanned) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('BANLI', style: AppTypography.caption2(color: AppColors.error)),
                      ),
                    ],
                  ],
                ),
                Text(user.email, style: AppTypography.caption1(color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.monetization_on_rounded, size: 14, color: AppColors.warning),
                    const SizedBox(width: 4),
                    Text('${user.credits} kredi', style: AppTypography.caption2(color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          
          // Actions
          PopupMenuButton(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
            color: context.isDarkMode ? AppColors.surfaceElevated : AppColors.surfaceElevatedLight,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: () => _showGiveCreditDialogForUser(user),
                child: Row(
                  children: [
                    Icon(Icons.card_giftcard_rounded, color: AppColors.warning, size: 20),
                    const SizedBox(width: 12),
                    Text('Kredi Ver', style: AppTypography.body()),
                  ],
                ),
              ),
              PopupMenuItem(
                onTap: () => _showGivePremiumDialogForUser(user),
                child: Row(
                  children: [
                    Icon(Icons.workspace_premium_rounded, color: AppColors.success, size: 20),
                    const SizedBox(width: 12),
                    Text('Premium Ver', style: AppTypography.body()),
                  ],
                ),
              ),
              PopupMenuItem(
                onTap: () {
                  if (user.isBanned) {
                    _unbanUser(user);
                  } else {
                    _showBanUserDialog(user);
                  }
                },
                child: Row(
                  children: [
                    Icon(
                      user.isBanned ? Icons.check_circle_rounded : Icons.block_rounded,
                      color: user.isBanned ? AppColors.success : AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      user.isBanned ? 'Banı Kaldır' : 'Banla',
                      style: AppTypography.body(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return Column(
      children: [
        // Filter tabs
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _FilterChip(
                label: 'Tümü',
                isSelected: _reportFilter == 'all',
                onTap: () {
                  setState(() => _reportFilter = 'all');
                  _loadReports();
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Bekleyen',
                isSelected: _reportFilter == 'pending',
                onTap: () {
                  setState(() => _reportFilter = 'pending');
                  _loadReports();
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Çözülen',
                isSelected: _reportFilter == 'resolved',
                onTap: () {
                  setState(() => _reportFilter = 'resolved');
                  _loadReports();
                },
              ),
            ],
          ),
        ),
        
        if (_isLoadingReports)
          const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
        else if (_reports.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline, color: AppColors.success, size: 48),
                  const SizedBox(height: 16),
                  Text('Rapor bulunamadı', style: AppTypography.body(color: AppColors.textSecondary)),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadReports,
              color: AppColors.primary,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _reports.length,
                itemBuilder: (context, index) {
                  final report = _reports[index];
                  return _buildReportCard(report);
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildReportCard(ReportItem report) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: report.isPending
                      ? AppColors.warning.withOpacity(0.2)
                      : AppColors.success.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  report.isPending ? 'Bekliyor' : 'Çözüldü',
                  style: AppTypography.caption2(
                    color: report.isPending ? AppColors.warning : AppColors.success,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(report.createdAt),
                style: AppTypography.caption2(color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.flag_rounded, size: 14, color: AppColors.error),
              const SizedBox(width: 4),
              Text(report.reason, style: AppTypography.caption1(color: AppColors.textSecondary)),
            ],
          ),
          if (report.description != null) ...[
            const SizedBox(height: 8),
            Text(report.description!, style: AppTypography.body(color: AppColors.textSecondary)),
          ],
          if (report.isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _resolveReport(report.id, 'approve'),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Onayla'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.success,
                      side: BorderSide(color: AppColors.success.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _resolveReport(report.id, 'reject'),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Reddet'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('UYGULAMA AYARLARI', style: AppTypography.caption1(color: AppColors.textMuted)),
          const SizedBox(height: 12),
          GlassContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.campaign_rounded,
                  title: 'Reklam Ayarları',
                  subtitle: 'Her 20 bağlantıda bir reklam',
                  onTap: () {},
                ),
                _Divider(),
                _SettingsTile(
                  icon: Icons.timer_rounded,
                  title: 'Next Cooldown',
                  subtitle: '5 next = 10sn, 10 next = 30sn',
                  onTap: () {},
                ),
                _Divider(),
                _SettingsTile(
                  icon: Icons.monetization_on_rounded,
                  title: 'Kredi Fiyatları',
                  subtitle: 'Paket fiyatlarını düzenle',
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // =====================================
  // DIALOGS & ACTIONS
  // =====================================

  void _showAnnouncementDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.isDarkMode ? AppColors.surfaceElevated : AppColors.surfaceElevatedLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.campaign_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('Duyuru Gönder', style: AppTypography.title2()),
          ],
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: AppTypography.body(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Duyuru mesajını yazın...',
            hintStyle: AppTypography.body(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: AppTypography.buttonMedium(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(adminServiceProvider).sendBroadcast(controller.text);
                _showSnackBar('Duyuru gönderildi!', AppColors.success);
              } catch (e) {
                _showSnackBar('Hata: $e', AppColors.error);
              }
            },
            child: Text('Gönder', style: AppTypography.buttonMedium(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showGiveCreditDialog() {
    final userController = TextEditingController();
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.isDarkMode ? AppColors.surfaceElevated : AppColors.surfaceElevatedLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.card_giftcard_rounded, color: AppColors.warning),
            const SizedBox(width: 8),
            Text('Kredi Ver', style: AppTypography.title2()),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: userController,
              style: AppTypography.body(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Kullanıcı ID',
                hintStyle: AppTypography.body(color: AppColors.textMuted),
                filled: true,
                fillColor: context.colors.surfaceColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: AppTypography.body(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Kredi miktarı',
                hintStyle: AppTypography.body(color: AppColors.textMuted),
                filled: true,
                fillColor: context.colors.surfaceColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: AppTypography.buttonMedium(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(adminServiceProvider).giveCredits(
                  userController.text,
                  int.parse(amountController.text),
                );
                _showSnackBar('Kredi verildi!', AppColors.success);
                _loadUsers();
              } catch (e) {
                _showSnackBar('Hata: $e', AppColors.error);
              }
            },
            child: Text('Ver', style: AppTypography.buttonMedium(color: AppColors.warning)),
          ),
        ],
      ),
    );
  }

  void _showGiveCreditDialogForUser(UserItem user) {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.isDarkMode ? AppColors.surfaceElevated : AppColors.surfaceElevatedLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('${user.username} - Kredi Ver', style: AppTypography.title2()),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          style: AppTypography.body(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Kredi miktarı',
            hintStyle: AppTypography.body(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: AppTypography.buttonMedium(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(adminServiceProvider).giveCredits(user.id, int.parse(amountController.text));
                _showSnackBar('Kredi verildi!', AppColors.success);
                _loadUsers();
              } catch (e) {
                _showSnackBar('Hata: $e', AppColors.error);
              }
            },
            child: Text('Ver', style: AppTypography.buttonMedium(color: AppColors.warning)),
          ),
        ],
      ),
    );
  }

  void _showGivePremiumDialogForUser(UserItem user) {
    String selectedDays = '30';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.isDarkMode ? AppColors.surfaceElevated : AppColors.surfaceElevatedLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('${user.username} - Premium Ver', style: AppTypography.title2()),
        content: DropdownButtonFormField<String>(
          value: selectedDays,
          dropdownColor: AppColors.surfaceElevated,
          style: AppTypography.body(color: AppColors.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          items: [
            DropdownMenuItem(value: '7', child: Text('1 Hafta')),
            DropdownMenuItem(value: '30', child: Text('1 Ay')),
            DropdownMenuItem(value: '90', child: Text('3 Ay')),
            DropdownMenuItem(value: '365', child: Text('1 Yıl')),
          ],
          onChanged: (v) => selectedDays = v!,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: AppTypography.buttonMedium(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(adminServiceProvider).givePremium(user.id, int.parse(selectedDays));
                _showSnackBar('Premium verildi!', AppColors.success);
                _loadUsers();
              } catch (e) {
                _showSnackBar('Hata: $e', AppColors.error);
              }
            },
            child: Text('Ver', style: AppTypography.buttonMedium(color: AppColors.success)),
          ),
        ],
      ),
    );
  }

  void _showBanUserDialog(UserItem user) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.isDarkMode ? AppColors.surfaceElevated : AppColors.surfaceElevatedLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('${user.username} - Banla', style: AppTypography.title2()),
        content: TextField(
          controller: reasonController,
          style: AppTypography.body(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Ban sebebi',
            hintStyle: AppTypography.body(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: AppTypography.buttonMedium(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(adminServiceProvider).banUser(user.id, reasonController.text);
                _showSnackBar('Kullanıcı banlandı!', AppColors.error);
                _loadUsers();
              } catch (e) {
                _showSnackBar('Hata: $e', AppColors.error);
              }
            },
            child: Text('Banla', style: AppTypography.buttonMedium(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _unbanUser(UserItem user) async {
    try {
      await ref.read(adminServiceProvider).unbanUser(user.id);
      _showSnackBar('Ban kaldırıldı!', AppColors.success);
      _loadUsers();
    } catch (e) {
      _showSnackBar('Hata: $e', AppColors.error);
    }
  }

  Future<void> _resolveReport(String reportId, String action) async {
    try {
      await ref.read(adminServiceProvider).resolveReport(reportId, action);
      _showSnackBar('Rapor ${action == 'approve' ? 'onaylandı' : 'reddedildi'}!', AppColors.success);
      _loadReports();
    } catch (e) {
      _showSnackBar('Hata: $e', AppColors.error);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(2).replaceAll('.', ',');
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
      if (diff.inHours < 24) return '${diff.inHours} saat önce';
      if (diff.inDays < 7) return '${diff.inDays} gün önce';
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}

// =====================================
// HELPER WIDGETS
// =====================================

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({required this.icon, required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(value, style: AppTypography.title1(color: color)),
          Text(title, style: AppTypography.caption1(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _RevenueRow extends StatelessWidget {
  final String title;
  final double amount;
  final int percentage;

  const _RevenueRow({required this.title, required this.amount, required this.percentage});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTypography.body(color: AppColors.textSecondary)),
              Text('₺${amount.toStringAsFixed(0)}', style: AppTypography.subheadlineMedium()),
            ],
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              Container(height: 6, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(3))),
              FractionallySizedBox(
                widthFactor: percentage / 100,
                child: Container(height: 6, decoration: BoxDecoration(gradient: AppGradients.button, borderRadius: BorderRadius.circular(3))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({required this.icon, required this.title, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: AppTypography.subheadlineMedium())),
            Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppGradients.button : null,
          color: isSelected ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: AppColors.borderSoft),
        ),
        child: Text(label, style: AppTypography.caption1(color: isSelected ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.body()),
                  Text(subtitle, style: AppTypography.caption1(color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 22),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(height: 0.5, margin: const EdgeInsets.only(left: 70), color: AppColors.borderSoft);
  }
}
