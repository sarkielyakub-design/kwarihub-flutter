
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/verify_otp_screen.dart';

import '../../features/dashboard/presentation/dashboard_screen.dart';

import '../../features/categories/presentation/categories_screen.dart';

import '../../features/products/presentation/products_screen.dart';
import '../../features/products/presentation/product_details_screen.dart';

import '../../features/cart/presentation/cart_screen.dart';
import '../../features/checkout/presentation/checkout_screen.dart';

import '../../features/orders/presentation/orders_screen.dart';
import '../../features/wishlist/presentation/wishlist_screen.dart';

import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/about_screen.dart';
import '../../features/profile/presentation/help_support_screen.dart';
import '../../features/profile/presentation/language_screen.dart';

import '../../features/wallet/presentation/wallet_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';

import '../../features/vendor/presentation/vendor_dashboard_screen.dart';

const Color _primaryBlue = Color(0xFF0D5CC7);
const Color _primaryNavy = Color(0xFF102F4F);

final GoRouter appRouter = GoRouter(
  initialLocation: '/',

  routes: [
    // ============================================================
    // AUTHENTICATION
    // ============================================================

    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),

    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),

    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),

    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),

    GoRoute(
      path: '/verify-otp',
      builder: (context, state) => const VerifyOtpScreen(),
    ),

    // ============================================================
    // CUSTOMER DASHBOARD
    // ============================================================

    GoRoute(
      path: '/home',
      builder: (context, state) => const DashboardScreen(),
    ),

    // ============================================================
    // CATEGORIES
    // ============================================================

    GoRoute(
      path: '/categories',
      builder: (context, state) => const CategoriesScreen(),
    ),

    GoRoute(
      path: '/categories/:id',
      builder: (context, state) {
        final categoryId = state.pathParameters['id']!;

        return ProductsScreen(
          categoryId: categoryId,
        );
      },
    ),

    // ============================================================
    // PRODUCTS
    // ============================================================

    GoRoute(
      path: '/products',
      builder: (context, state) => const ProductsScreen(),
    ),

    GoRoute(
      path: '/products/:id',
      builder: (context, state) {
        final productId = state.pathParameters['id']!;

        return ProductDetailsScreen(
          productId: productId,
        );
      },
    ),

    // ============================================================
    // CART AND CHECKOUT
    // ============================================================

    GoRoute(
      path: '/cart',
      builder: (context, state) => const CartScreen(),
    ),

    GoRoute(
      path: '/checkout',
      builder: (context, state) => const CheckoutScreen(),
    ),

    // ============================================================
    // CUSTOMER ORDERS
    // ============================================================

    GoRoute(
      path: '/orders',
      name: 'orders',
      builder: (context, state) => const OrdersScreen(),
    ),

    // ============================================================
    // WISHLIST
    // ============================================================

    GoRoute(
      path: '/wishlist',
      builder: (context, state) => const WishlistScreen(),
    ),

    // ============================================================
    // PROFILE
    // ============================================================

    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),

    // ============================================================
    // ABOUT KWARIHUB
    // ============================================================

    GoRoute(
      path: '/about',
      builder: (context, state) => const AboutScreen(),
    ),

    // ============================================================
    // HELP AND SUPPORT
    // ============================================================

    GoRoute(
      path: '/help-support',
      builder: (context, state) => const HelpSupportScreen(),
    ),

    // ============================================================
    // LANGUAGE SETTINGS
    // ============================================================

    GoRoute(
      path: '/language',
      builder: (context, state) => const LanguageScreen(),
    ),

    // ============================================================
    // WALLET
    // ============================================================

    GoRoute(
      path: '/wallet',
      builder: (context, state) => const WalletScreen(),
    ),

    // ============================================================
    // NOTIFICATIONS
    // ============================================================

    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),

    // ============================================================
    // VENDOR
    // ============================================================

    GoRoute(
      path: '/vendor',
      builder: (context, state) => const VendorDashboardScreen(),
    ),
  ],

  // ==============================================================
  // ROUTE ERROR
  // ==============================================================

  errorBuilder: (context, state) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: _primaryBlue,
              ),

              const SizedBox(height: 16),

              const Text(
                'Page Not Found',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: _primaryNavy,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'The page "${state.uri}" could not be found.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  },
);
