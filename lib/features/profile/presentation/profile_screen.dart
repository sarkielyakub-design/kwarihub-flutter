import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../auth/data/auth_api.dart';
import '../models/user_profile.dart';
import '../providers/profile_provider.dart';

// ================================================================
// KWARIHUB PROFILE COLORS
// ================================================================

const Color primaryBlue = Color(0xFF0D5CC7);
const Color darkBlue = Color(0xFF102F4F);
const Color lightBlue = Color(0xFFF4F8FF);
const Color backgroundColor = Color(0xFFF7F9FC);
const Color borderColor = Color(0xFFE2EAF3);

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState
    extends ConsumerState<ProfileScreen> {
  bool _loggingOut = false;

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: darkBlue,
          ),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: darkBlue,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: false,
      ),
      body: profileState.when(
        loading: () => const _ProfileLoading(),
        error: (error, stackTrace) {
          return _ProfileError(
            message: ref
                .read(profileProvider.notifier)
                .errorMessage(error),
            onRetry: () {
              ref
                  .read(profileProvider.notifier)
                  .refresh();
            },
          );
        },
        data: (profile) {
          return RefreshIndicator(
            color: primaryBlue,
            onRefresh: () {
              return ref
                  .read(profileProvider.notifier)
                  .refresh();
            },
            child: _ProfileContent(
              profile: profile,
              onEditProfile: () {
                _openEditProfile(context);
              },
              onChangePassword: () {
                _openChangePassword(context);
              },
              onLogout: () {
                _confirmLogout(context);
              },
              onWishlist: () {
                context.push('/wishlist');
              },
              onCart: () {
                context.push('/cart');
              },
              onOrders: () {
  context.push('/orders');

              },onNotifications: () {
  context.push('/notifications');
},
onLanguage: () {
  context.push('/language');
},
onHelp: () {
  context.push('/help-support');
},
onAbout: () {
  context.push('/about');
},
            ),
          );
        },
      ),
      bottomNavigationBar:
          const _ProfileBottomNavigation(),
    );
  }

  // ============================================================
  // EDIT PROFILE
  // ============================================================

  void _openEditProfile(BuildContext context) {
    if (_hasRoute(context, '/profile/edit')) {
      context.push('/profile/edit');
      return;
    }

    _showMessage(
      'Edit Profile screen will be connected next.',
    );
  }

  // ============================================================
  // CHANGE PASSWORD
  // ============================================================

  void _openChangePassword(BuildContext context) {
    if (_hasRoute(context, '/profile/change-password')) {
      context.push('/profile/change-password');
      return;
    }

    _showMessage(
      'Change Password screen will be connected next.',
    );
  }

  // ============================================================
  // CHECK ROUTE
  // ============================================================

  bool _hasRoute(
    BuildContext context,
    String path,
  ) {
    try {
      GoRouter.of(context).configuration.findMatch(Uri.parse(path));
      return true;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // LOGOUT CONFIRMATION
  // ============================================================

  Future<void> _confirmLogout(
    BuildContext context,
  ) async {
    if (_loggingOut) {
      return;
    }

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Log out?',
            style: TextStyle(
              color: darkBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'Are you sure you want to log out of your KwariHub account?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: darkBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text(
                'Log out',
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !context.mounted) {
      return;
    }

    await _logout(context);
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout(
    BuildContext context,
  ) async {
    setState(() {
      _loggingOut = true;
    });

    try {
      await AuthApi().logout();

      if (!context.mounted) {
        return;
      }

      context.go('/login');
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      setState(() {
        _loggingOut = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _authErrorMessage(error),
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  // ============================================================
  // AUTH ERROR
  // ============================================================

  String _authErrorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;

      if (data is Map<String, dynamic>) {
        final detail = data['detail'];

        if (detail is String &&
            detail.trim().isNotEmpty) {
          return detail;
        }

        final message = data['message'];

        if (message is String &&
            message.trim().isNotEmpty) {
          return message;
        }
      }

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return 'Connection timed out. Please try again.';

        case DioExceptionType.connectionError:
          return 'Unable to connect to KwariHub server.';

        default:
          return 'Unable to log out. Please try again.';
      }
    }

    return error
        .toString()
        .replaceFirst('Exception: ', '');
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
  }
}

// ================================================================
// PROFILE CONTENT
// ================================================================

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.profile,
    required this.onEditProfile,
    required this.onChangePassword,
    required this.onLogout,
    required this.onWishlist,
    required this.onCart,
    required this.onOrders,
    required this.onNotifications,
    required this.onLanguage,
    required this.onHelp,
    required this.onAbout,
  });

  final UserProfile profile;

  final VoidCallback onEditProfile;
  final VoidCallback onChangePassword;
  final VoidCallback onLogout;

  final VoidCallback onWishlist;
  final VoidCallback onCart;
  final VoidCallback onOrders;

  final VoidCallback onNotifications;
  final VoidCallback onLanguage;

  final VoidCallback onHelp;
  final VoidCallback onAbout;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(
        16,
        18,
        16,
        110,
      ),
      children: [
        _ProfileHeader(
          profile: profile,
          onEdit: onEditProfile,
        ),

        const SizedBox(height: 24),

        const _SectionTitle(
          title: 'My Account',
        ),

        const SizedBox(height: 10),

        _ProfileMenuCard(
          icon: Icons.person_outline_rounded,
          title: 'Personal Information',
          subtitle: 'Manage your account information',
          onTap: onEditProfile,
        ),

        const SizedBox(height: 10),

        _ProfileMenuCard(
          icon: Icons.shopping_bag_outlined,
          title: 'My Orders',
          subtitle: 'View and track your orders',
          onTap: onOrders,
        ),

        const SizedBox(height: 10),

        _ProfileMenuCard(
          icon: Icons.favorite_border_rounded,
          title: 'Wishlist',
          subtitle: 'Products you saved',
          onTap: onWishlist,
        ),

        const SizedBox(height: 10),

        _ProfileMenuCard(
          icon: Icons.shopping_cart_outlined,
          title: 'My Cart',
          subtitle: 'View products in your cart',
          onTap: onCart,
        ),

        const SizedBox(height: 24),

        const _SectionTitle(
          title: 'Preferences',
        ),

        const SizedBox(height: 10),

        _ProfileMenuCard(
          icon: Icons.notifications_none_rounded,
          title: 'Notifications',
          subtitle: 'Manage your notification preferences',
          onTap: onNotifications,
        ),

        const SizedBox(height: 10),

        _ProfileMenuCard(
          icon: Icons.language_rounded,
          title: 'Language',
          subtitle: 'English',
          onTap: onLanguage,
        ),

        const SizedBox(height: 10),

        _ProfileMenuCard(
          icon: Icons.lock_outline_rounded,
          title: 'Security',
          subtitle: 'Change your password',
          onTap: onChangePassword,
        ),

        const SizedBox(height: 24),

        const _SectionTitle(
          title: 'Support',
        ),

        const SizedBox(height: 10),

        _ProfileMenuCard(
          icon: Icons.help_outline_rounded,
          title: 'Help & Support',
          subtitle: 'Get help with KwariHub',
          onTap: onHelp,
        ),

        const SizedBox(height: 10),

        _ProfileMenuCard(
          icon: Icons.info_outline_rounded,
          title: 'About KwariHub',
          subtitle: 'Learn more about KwariHub',
          onTap: onAbout,
        ),

        const SizedBox(height: 28),

        _LogoutButton(
          loading: false,
          onTap: onLogout,
        ),

        const SizedBox(height: 20),

        Center(
          child: Text(
            'KwariHub',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        const SizedBox(height: 4),

        Center(
          child: Text(
            'Textile Marketplace',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

// ================================================================
// PROFILE HEADER
// ================================================================

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.profile,
    required this.onEdit,
  });

  final UserProfile profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = _buildAvatarUrl(
      profile.avatar,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.04,
            ),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _ProfileAvatar(
                profile: profile,
                avatarUrl: avatarUrl,
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: darkBlue,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      '@${profile.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: primaryBlue,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      profile.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Material(
                color: lightBlue,
                borderRadius:
                    BorderRadius.circular(12),
                child: InkWell(
                  onTap: onEdit,
                  borderRadius:
                      BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.all(11),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: primaryBlue,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: lightBlue,
              borderRadius:
                  BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.phone_outlined,
                  color: primaryBlue,
                  size: 19,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    profile.phone,
                    style: const TextStyle(
                      color: darkBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// PROFILE AVATAR
// ================================================================

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.profile,
    required this.avatarUrl,
  });

  final UserProfile profile;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: primaryBlue.withValues(
            alpha: 0.15,
          ),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: avatarUrl != null
            ? Image.network(
                avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (
                  context,
                  error,
                  stackTrace,
                ) {
                  return _InitialAvatar(
                    initials: profile.initials,
                  );
                },
                loadingBuilder: (
                  context,
                  child,
                  loadingProgress,
                ) {
                  if (loadingProgress == null) {
                    return child;
                  }

                  return const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primaryBlue,
                      ),
                    ),
                  );
                },
              )
            : _InitialAvatar(
                initials: profile.initials,
              ),
      ),
    );
  }
}

// ================================================================
// INITIAL AVATAR
// ================================================================

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({
    required this.initials,
  });

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: lightBlue,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: primaryBlue,
          fontSize: 25,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ================================================================
// AVATAR URL
// ================================================================

String? _buildAvatarUrl(
  String? path,
) {
  if (path == null) {
    return null;
  }

  var cleanPath = path.trim();

  if (cleanPath.isEmpty) {
    return null;
  }

  if (cleanPath.startsWith('http://') ||
      cleanPath.startsWith('https://')) {
    return cleanPath;
  }

  while (cleanPath.startsWith('/')) {
    cleanPath = cleanPath.substring(1);
  }

  return '${AppConfig.storageBaseUrl}/$cleanPath';
}

// ================================================================
// SECTION TITLE
// ================================================================

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return const Text(
      '',
    );
  }
}

// ================================================================
// MENU CARD
// ================================================================

class _ProfileMenuCard extends StatelessWidget {
  const _ProfileMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: lightBlue,
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: primaryBlue,
                  size: 23,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: darkBlue,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
                size: 25,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// LOGOUT BUTTON
// ================================================================

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({
    required this.loading,
    required this.onTap,
  });

  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: 16,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.red.shade100,
            ),
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              if (loading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.red.shade600,
                  ),
                )
              else
                Icon(
                  Icons.logout_rounded,
                  color: Colors.red.shade600,
                  size: 21,
                ),

              const SizedBox(width: 9),

              Text(
                loading ? 'Logging out...' : 'Log out',
                style: TextStyle(
                  color: Colors.red.shade600,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// LOADING
// ================================================================

class _ProfileLoading extends StatelessWidget {
  const _ProfileLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        16,
        18,
        16,
        110,
      ),
      children: [
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(20),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: primaryBlue,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const _LoadingLine(width: 120),
        const SizedBox(height: 12),
        const _LoadingCard(),
        const SizedBox(height: 10),
        const _LoadingCard(),
        const SizedBox(height: 10),
        const _LoadingCard(),
      ],
    );
  }
}

class _LoadingLine extends StatelessWidget {
  const _LoadingLine({
    required this.width,
  });

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 17,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius:
            BorderRadius.circular(8),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
        ),
      ),
    );
  }
}

// ================================================================
// ERROR
// ================================================================

class _ProfileError extends StatelessWidget {
  const _ProfileError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: primaryBlue,
      onRefresh: () async {
        onRetry();
      },
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),

          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: lightBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_off_outlined,
              color: primaryBlue,
              size: 34,
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Unable to load profile',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: darkBlue,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 20),

          Center(
            child: FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text(
                'Try Again',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// BOTTOM NAVIGATION
// ================================================================

class _ProfileBottomNavigation extends StatelessWidget {
  const _ProfileBottomNavigation();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                active: false,
                onTap: () => context.go('/home'),
              ),
              _NavItem(
                icon: Icons.category_outlined,
                activeIcon: Icons.category_rounded,
                label: 'Categories',
                active: false,
                onTap: () => context.go('/categories'),
              ),
              _NavItem(
                icon: Icons.shopping_cart_outlined,
                activeIcon: Icons.shopping_cart_rounded,
                label: 'Cart',
                active: false,
                onTap: () => context.go('/cart'),
              ),
              _NavItem(
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long_rounded,
                label: 'Orders',
                active: false,
                onTap: () => context.go('/orders'),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                active: true,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// ================================================================
// NAV ITEM
// ================================================================

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        active ? primaryBlue : Colors.grey.shade500;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              active ? activeIcon : icon,
              color: color,
              size: 23,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: active
                    ? FontWeight.w800
                    : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}