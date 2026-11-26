import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'constants/app_routes.dart';
import 'constants/app_strings.dart';
import 'constants/app_theme.dart';
import 'providers/community_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/post_provider.dart';
import 'providers/search_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'providers/vote_provider.dart';
import 'screens/community_details_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell_screen.dart';
import 'screens/post_details_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const MedditApp());
}

class MedditApp extends StatelessWidget {
  const MedditApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProxyProvider<UserProvider, CommunityProvider>(
          create: (context) => CommunityProvider()
            ..syncUserBranch(
              context.read<UserProvider>().currentUser.branch,
              notify: false,
            ),
          update: (_, userProvider, communityProvider) {
            final provider = communityProvider ?? CommunityProvider();
            provider.syncUserBranch(
              userProvider.currentUser.branch,
              notify: false,
            );
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => PostProvider()),
        ChangeNotifierProvider(create: (_) => VoteProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: AppRoutes.splash,
            onGenerateRoute: _onGenerateRoute,
          );
        },
      ),
    );
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SplashScreen(),
        );
      case AppRoutes.login:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const LoginScreen(),
        );
      case AppRoutes.mainShell:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const MainShellScreen(),
        );
      case AppRoutes.communityDetails:
        final communityId = settings.arguments as String? ?? '';
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => CommunityDetailsScreen(communityId: communityId),
        );
      case AppRoutes.postDetails:
        final postId = settings.arguments as String? ?? '';
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => PostDetailsScreen(postId: postId),
        );
      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SplashScreen(),
        );
    }
  }
}
