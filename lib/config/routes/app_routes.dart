import 'package:flutter/material.dart';
import '../../presentation/home/home_page.dart';
import '../../presentation/explore/explore_page.dart';
import '../../presentation/plant_detail/plant_detail_page.dart';
import '../../presentation/simulation/simulation_screen.dart';
import '../../presentation/lg_connection/lg_connection_page.dart';
import '../../presentation/splash/splash_screen.dart';
import '../../presentation/home/search_screen.dart';
import '../../presentation/home/bloc/search_bloc.dart';
import '../../presentation/about/about_screen.dart';
import '../../presentation/infrastructure_map/infrastructure_map_screen.dart';
import '../../presentation/explore/bloc/explore_bloc.dart';
import '../../domain/repository/cvs_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../di/di.dart';
import '../theme/theme_controller.dart';

class AppRoutes {
  AppRoutes._();
  static const String splash = '/splash';
  static const String home = '/';
  static const String explore = '/explore';
  static const String plantDetail = '/plant-detail';
  static const String simulation = '/simulation';
  static const String lgSettings = '/lg-settings';
  static const String search = '/search';
  static const String about = '/about';
  static const String infrastructureMap = '/infrastructure-map';
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _buildRoute(const SplashScreen(), settings);
      case home:
        return _buildRoute(const HomePage(), settings);
      case explore:
        return _buildRoute(
          ExploreScreen(arguments: settings.arguments as Map<String, dynamic>?),
          settings,
        );
      case plantDetail:
        return _buildRoute(
          PlantDetailScreen(
            arguments: settings.arguments as Map<String, dynamic>?,
          ),
          settings,
        );
      case simulation:
        return _buildRoute(
          ScenarioSimulationScreen(
            bloc: (settings.arguments as Map<String, dynamic>?)?['bloc'],
          ),
          settings,
        );
      case lgSettings:
        return _buildRoute(const LgSettingsScreen(), settings);
      case search:
        return _buildRoute(
          BlocProvider(
            create: (context) => sl<SearchBloc>(),
            child: const SearchScreen(),
          ),
          settings,
        );
      case about:
        return _buildRoute(const AboutScreen(), settings);
      case infrastructureMap:
        return _buildRoute(
          BlocProvider(
            create: (context) => sl<ExploreBloc>(),
            child: RepositoryProvider<CvsRepository>(
              create: (context) => sl<CvsRepository>(),
              child: const InfrastructureMapScreen(),
            ),
          ),
          settings,
        );
      default:
        return _buildRoute(const HomePage(), settings);
    }
  }

  static PageRouteBuilder _buildRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) =>
          _ThemeRefreshBoundary(child: page),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;
        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }
}

/// Rebuilds legacy widgets that still read the app palette outside an inherited
/// theme dependency when the platform brightness changes in system mode.
class _ThemeRefreshBoundary extends StatelessWidget {
  final Widget child;
  const _ThemeRefreshBoundary({required this.child});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      ThemeController.instance.themeModeNotifier,
      ThemeController.instance.platformBrightnessRevision,
    ]),
    builder: (context, _) => KeyedSubtree(
      key: ValueKey(
        '${ThemeController.instance.currentThemeMode}-${MediaQuery.platformBrightnessOf(context)}-${ThemeController.instance.platformBrightnessRevision.value}',
      ),
      child: child,
    ),
  );
}
