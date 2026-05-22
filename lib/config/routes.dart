import 'package:flutter/material.dart';
import 'package:ecogrid_intelligence/presentation/screens/home_screen.dart';
import 'package:ecogrid_intelligence/presentation/screens/explore_screen.dart';
import 'package:ecogrid_intelligence/presentation/screens/plant_detail_screen.dart';
import 'package:ecogrid_intelligence/presentation/screens/climate_dashboard_screen.dart';
import 'package:ecogrid_intelligence/presentation/screens/timeline_screen.dart';
import 'package:ecogrid_intelligence/presentation/screens/forecast_screen.dart';
import 'package:ecogrid_intelligence/presentation/screens/ai_analysis_screen.dart';
import 'package:ecogrid_intelligence/presentation/screens/simulation_screen.dart';
import 'package:ecogrid_intelligence/presentation/screens/filter_screen.dart';
import 'package:ecogrid_intelligence/presentation/screens/lg_settings_screen.dart';
import 'package:ecogrid_intelligence/presentation/screens/lg_visualization_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String explore = '/explore';
  static const String plantDetail = '/plant-detail';
  static const String climateDashboard = '/climate-dashboard';
  static const String timeline = '/timeline';
  static const String forecast = '/forecast';
  static const String aiAnalysis = '/ai-analysis';
  static const String simulation = '/simulation';
  static const String filter = '/filter';
  static const String lgSettings = '/lg-settings';
  static const String lgVisualization = '/lg-visualization';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return _buildRoute(const HomeScreen(), settings);
      case explore:
        return _buildRoute(
          ExploreScreen(arguments: settings.arguments as Map<String, dynamic>?),
          settings,
        );
      case plantDetail:
        return _buildRoute(
          PlantDetailScreen(
              arguments: settings.arguments as Map<String, dynamic>?),
          settings,
        );
      case climateDashboard:
        return _buildRoute(const ClimateDashboardScreen(), settings);
      case timeline:
        return _buildRoute(const TimelineScreen(), settings);
      case forecast:
        return _buildRoute(const ForecastScreen(), settings);
      case aiAnalysis:
        return _buildRoute(
          AiAnalysisScreen(
              arguments: settings.arguments as Map<String, dynamic>?),
          settings,
        );
      case simulation:
        return _buildRoute(
          SimulationScreen(
              arguments: settings.arguments as Map<String, dynamic>?),
          settings,
        );
      case filter:
        return _buildRoute(
          FilterScreen(arguments: settings.arguments as Map<String, dynamic>?),
          settings,
        );
      case lgSettings:
        return _buildRoute(const LgSettingsScreen(), settings);
      case lgVisualization:
        return _buildRoute(const LgVisualizationScreen(), settings);
      default:
        return _buildRoute(const HomeScreen(), settings);
    }
  }

  static PageRouteBuilder _buildRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;
        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }
}
