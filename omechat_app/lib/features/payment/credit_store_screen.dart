import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/glowing_button.dart';
import '../../providers/auth_provider.dart';

class CreditStoreScreen extends ConsumerStatefulWidget {
  const CreditStoreScreen({super.key});

  @override
  ConsumerState<CreditStoreScreen> createState() => _CreditStoreScreenState();
}

class _CreditStoreScreenState extends ConsumerState<CreditStoreScreen> {
  int? _selectedPackage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Kredi Yükle', style: AppTypography.title2()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Card
            const _BalanceCard(),
            
            const SizedBox(height: 24),
            
            // Credit Usage Info
            _buildCreditUsageInfo(),
            
            const SizedBox(height: 24),
            
            // Credit Packages
            Text(
              'KREDİ PAKETLERİ',
              style: AppTypography.caption1(color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            _buildPackagesGrid(),
            
            const SizedBox(height: 24),
            
            // Buy Button
            if (_selectedPackage != null)
              GlowingButton.rectangle(
                onPressed: _purchaseCredits,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shopping_cart_rounded, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Satın Al',
                      style: AppTypography.buttonLarge(color: Colors.white),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditUsageInfo() {
    final usages = [
      {'icon': Icons.wc_rounded, 'title': 'Cinsiyet Seçme', 'cost': '30', 'desc': 'Kadın / Erkek filtresi'},
      {'icon': Icons.public_rounded, 'title': 'Ülke Seçme', 'cost': '20', 'desc': 'İstediğin ülkeyi seç'},
      {'icon': Icons.replay_rounded, 'title': 'Reconnect', 'cost': '40', 'desc': 'Aynı kişiyle tekrar bağlan'},
      {'icon': Icons.face_retouching_natural_rounded, 'title': 'Yüz Filtreleri', 'cost': '10', 'desc': 'Efektleri aç'},
      {'icon': Icons.hd_rounded, 'title': 'HD Görüntü', 'cost': '15', 'desc': 'Karşı tarafı HD gör'},
      {'icon': Icons.verified_rounded, 'title': 'VIP Rozet', 'cost': '100', 'desc': 'Profiline rozet ekle'},
    ];

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'KREDİ KULLANIM ALANLARI',
                style: AppTypography.caption1(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...usages.map((usage) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    usage['icon'] as IconData,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        usage['title'] as String,
                        style: AppTypography.subheadlineMedium(),
                      ),
                      Text(
                        usage['desc'] as String,
                        style: AppTypography.caption2(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.monetization_on_rounded, color: AppColors.warning, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        usage['cost'] as String,
                        style: AppTypography.caption1(color: AppColors.warning),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPackagesGrid() {
    final packages = [
      {'credits': 100, 'price': '24,99', 'id': 0},
      {'credits': 500, 'price': '79,99', 'id': 1, 'tag': 'POPÜLER'},
      {'credits': 1000, 'price': '129,99', 'id': 2, 'bonus': '+50'},
      {'credits': 5000, 'price': '399,99', 'id': 3, 'tag': 'EN İYİ', 'bonus': '+500'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: packages.length,
      itemBuilder: (context, index) {
        final pkg = packages[index];
        final isSelected = _selectedPackage == pkg['id'];
        return _buildPackageCard(
          credits: pkg['credits'] as int,
          price: pkg['price'] as String,
          tag: pkg['tag'] as String?,
          bonus: pkg['bonus'] as String?,
          isSelected: isSelected,
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedPackage = pkg['id'] as int);
          },
        );
      },
    );
  }

  Widget _buildPackageCard({
    required int credits,
    required String price,
    String? tag,
    String? bonus,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.durationFast,
        decoration: BoxDecoration(
          gradient: isSelected ? AppGradients.button : null,
          color: isSelected ? null : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : (tag != null ? AppColors.primary : AppColors.borderSoft),
            width: isSelected ? 0 : (tag != null ? 2 : 1),
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 0,
            ),
          ] : null,
        ),
        child: Stack(
          children: [
            if (tag != null)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withOpacity(0.2) : AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tag,
                    style: AppTypography.caption2(color: Colors.white),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.monetization_on_rounded,
                    size: 40,
                    color: isSelected ? Colors.white : AppColors.warning,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$credits',
                        style: AppTypography.title1(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      if (bonus != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 2),
                          child: Text(
                            bonus,
                            style: AppTypography.caption1(
                              color: isSelected ? Colors.white.withOpacity(0.8) : AppColors.success,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    'Kredi',
                    style: AppTypography.body(
                      color: isSelected ? Colors.white.withOpacity(0.8) : AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white.withOpacity(0.2) : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '₺$price',
                      textAlign: TextAlign.center,
                      style: AppTypography.buttonMedium(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _purchaseCredits() {
    HapticFeedback.mediumImpact();
    final packages = [
      {'credits': 100, 'price': '24,99'},
      {'credits': 500, 'price': '79,99'},
      {'credits': 1000, 'price': '129,99'},
      {'credits': 5000, 'price': '399,99'},
    ];
    final pkg = packages[_selectedPackage!];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.monetization_on_rounded, color: AppColors.warning),
            const SizedBox(width: 8),
            Text('Kredi Satın Al', style: AppTypography.title2()),
          ],
        ),
        content: Text(
          '${pkg['credits']} kredi için ₺${pkg['price']} ödeme yapılacak.\n\nSatın alma özelliği yakında eklenecek!',
          style: AppTypography.body(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: AppTypography.buttonMedium(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${pkg['credits']} kredi satın alma başlatıldı...'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            child: Text('Satın Al', style: AppTypography.buttonMedium(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends ConsumerWidget {
  const _BalanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final balance = user?.credits ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppGradients.button,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mevcut Krediniz',
                  style: AppTypography.body(color: Colors.white.withOpacity(0.8)),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$balance',
                      style: AppTypography.extraLargeTitle(color: Colors.white),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 6),
                      child: Text(
                        'KREDİ',
                        style: AppTypography.caption1(color: Colors.white.withOpacity(0.6)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
