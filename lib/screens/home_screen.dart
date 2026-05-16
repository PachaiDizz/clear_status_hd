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

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: _buildAppBar(controller),
      body: Column(
        children: [
          // ── Tab selector ──────────────────────────────────
          _buildTabSelector(controller),

          // ── Content ───────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (controller.mediaItems.isEmpty) {
                return _buildEmptyState(controller);
              }
              return _buildMediaList(controller);
            }),
          ),
        ],
      ),

      // ── FAB ───────────────────────────────────────────────
      floatingActionButton: _buildFab(controller),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // ── AppBar ────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(HomeController controller) {
    return AppBar(
      backgroundColor: AppTheme.surfaceDark,
      elevation: 0,
      titleSpacing: 20,
      title: Row(
        children: [
          // Logo box
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.logoBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.18),
              ),
            ),
            child: const Center(
              child: Text(
                'HD',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Status HD',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
      actions: [
        Obx(() => controller.mediaItems.isNotEmpty
            ? GestureDetector(
                onTap: controller.compressAll,
                child: const Padding(
                  padding: EdgeInsets.only(right: 20),
                  child: Text(
                    'Compress all',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              )
            : const SizedBox()),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Divider(
          height: 0,
          thickness: 0.5,
          color: Colors.white.withOpacity(0.06),
        ),
      ),
    );
  }

  // ── Tab selector ──────────────────────────────────────────
  Widget _buildTabSelector(HomeController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Obx(() {
        final idx = controller.selectedTabIndex.value;
        return Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppTheme.trackDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Row(
            children: [
              _tabButton(
                label: 'Video',
                icon: Icons.videocam_rounded,
                selected: idx == 0,
                onTap: () => controller.selectedTabIndex.value = 0,
              ),
              _tabButton(
                label: 'Photo',
                icon: Icons.photo_rounded,
                selected: idx == 1,
                onTap: () => controller.selectedTabIndex.value = 1,
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _tabButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? Colors.black : Colors.white.withOpacity(0.38),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color:
                      selected ? Colors.black : Colors.white.withOpacity(0.38),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────
  Widget _buildEmptyState(HomeController controller) {
    return Obx(() {
      final isVideo = controller.selectedTabIndex.value == 0;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon glyph
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.logoBg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.15),
                ),
              ),
              child: Icon(
                isVideo ? Icons.videocam_rounded : Icons.photo_rounded,
                color: AppTheme.primaryColor,
                size: 36,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'No media yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Pick a video or photo to compress\nfor crystal-clear WhatsApp Status',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.38),
                height: 1.6,
              ),
            ),

            const SizedBox(height: 36),

            // ── Big pick buttons ────────────────────────────
            Row(
              children: [
                _bigPickButton(
                  icon: Icons.videocam_rounded,
                  label: 'Pick Video',
                  sublabel: 'Up to 10 min',
                  selected: isVideo,
                  onTap: controller.pickVideo,
                ),
                const SizedBox(width: 12),
                _bigPickButton(
                  icon: Icons.photo_rounded,
                  label: 'Pick Photo',
                  sublabel: 'Any size',
                  selected: !isVideo,
                  onTap: controller.pickPhoto,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _bigPickButton({
    required IconData icon,
    required String label,
    required String sublabel,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 28),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.primaryColor.withOpacity(0.10)
                : AppTheme.cardDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppTheme.primaryColor.withOpacity(0.28)
                  : AppTheme.borderSubtle,
              width: selected ? 1.5 : 0.5,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.primaryColor.withOpacity(0.15)
                      : Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: selected
                      ? AppTheme.primaryColor
                      : Colors.white.withOpacity(0.25),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color:
                      selected ? Colors.white : Colors.white.withOpacity(0.55),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                sublabel,
                style: TextStyle(
                  fontSize: 11,
                  color: selected
                      ? AppTheme.primaryColor.withOpacity(0.7)
                      : Colors.white.withOpacity(0.25),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Media list ────────────────────────────────────────────
  Widget _buildMediaList(HomeController controller) {
    return Obx(() => ListView.builder(
          padding: const EdgeInsets.only(top: 12, bottom: 110),
          itemCount: controller.mediaItems.length,
          itemBuilder: (_, index) {
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
        ));
  }

  // ── FAB ───────────────────────────────────────────────────
  Widget _buildFab(HomeController controller) {
    return Obx(() {
      final isVideo = controller.selectedTabIndex.value == 0;
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        width: double.infinity,
        child: FloatingActionButton.extended(
          onPressed: isVideo ? controller.pickVideo : controller.pickPhoto,
          backgroundColor: AppTheme.primaryColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: Icon(
            isVideo ? Icons.videocam_rounded : Icons.photo_rounded,
            color: Colors.black,
            size: 20,
          ),
          label: Text(
            isVideo ? 'Pick Video' : 'Pick Photo',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      );
    });
  }
}
