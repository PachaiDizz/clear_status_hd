import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/app_theme.dart';
import '../widgets/media_card.dart';
import 'home_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.accentColor],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.hd_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            const Text('HD Status'),
          ],
        ),
        actions: [
          Obx(() => controller.mediaItems.isNotEmpty
              ? TextButton(
                  onPressed: controller.compressAll,
                  child: const Text(
                    'All',
                    style: TextStyle(color: AppTheme.primaryColor),
                  ),
                )
              : const SizedBox()),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── Tab Selector ──
          _buildTabSelector(controller, isDark),

          // ── Media List ──
          Expanded(
            child: Obx(() {
              if (controller.mediaItems.isEmpty) {
                return _buildEmptyState(controller);
              }
              return ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 100),
                itemCount: controller.mediaItems.length,
                itemBuilder: (context, index) {
                  final item = controller.mediaItems[index];
                  return MediaCard(
                    key: ValueKey(item.id),
                    item: item,
                    onCompress: () => controller.compressItem(item.id),
                    onShare: () => controller.shareToWhatsApp(item.id),
                    onSplitShare: () => controller.splitAndShare(item.id),
                    onRemove: () => controller.removeItem(item.id),
                  );
                },
              );
            }),
          ),
        ],
      ),

      // ── FAB ──
      floatingActionButton: Obx(
        () => FloatingActionButton.extended(
          onPressed: controller.selectedTabIndex.value == 0
              ? controller.pickVideo
              : controller.pickPhoto,
          backgroundColor: AppTheme.primaryColor,
          icon: Icon(
            controller.selectedTabIndex.value == 0
                ? Icons.video_library_rounded
                : Icons.photo_library_rounded,
            color: Colors.white,
          ),
          label: Text(
            controller.selectedTabIndex.value == 0
                ? 'Pick Video'
                : 'Pick Photo',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildTabSelector(HomeController controller, bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Obx(
        () => Row(
          children: [
            _tabButton(
              label: '🎬 Video',
              selected: controller.selectedTabIndex.value == 0,
              onTap: () => controller.selectedTabIndex.value = 0,
            ),
            _tabButton(
              label: '📷 Photo',
              selected: controller.selectedTabIndex.value == 1,
              onTap: () => controller.selectedTabIndex.value = 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: selected ? Colors.white : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(HomeController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.2),
                  AppTheme.accentColor.withOpacity(0.2),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.hd_rounded,
              size: 52,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No media yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pick a video or photo to compress\nfor crystal-clear WhatsApp Status',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _quickPickButton(
                icon: Icons.video_library_rounded,
                label: 'Video',
                onTap: controller.pickVideo,
              ),
              const SizedBox(width: 16),
              _quickPickButton(
                icon: Icons.photo_library_rounded,
                label: 'Photo',
                onTap: controller.pickPhoto,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickPickButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.accentColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 30),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
