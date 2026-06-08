import 'package:flutter/material.dart';
import 'package:ecogrid_intelligence/presentation/home/home_page.dart';
import 'package:ecogrid_intelligence/presentation/explore/explore_page.dart';
import 'package:ecogrid_intelligence/presentation/plant_detail/plant_detail_page.dart';
import 'package:ecogrid_intelligence/presentation/climate_dashboard/climate_dashboard_page.dart';
import 'package:ecogrid_intelligence/presentation/timeline/timeline_page.dart';
import 'package:ecogrid_intelligence/presentation/forecast/forecast_page.dart';
import 'package:ecogrid_intelligence/presentation/ai_analysis/ai_analysis_page.dart';
import 'package:ecogrid_intelligence/presentation/simulation/simulation_screen.dart';
import 'package:ecogrid_intelligence/presentation/filter/filter_page.dart';
import 'package:ecogrid_intelligence/presentation/lg_connection/lg_connection_page.dart';
import 'package:ecogrid_intelligence/presentation/lg_visualization/lg_visualization_page.dart';
import 'package:ecogrid_intelligence/presentation/home/search_screen.dart';
import 'package:ecogrid_intelligence/presentation/home/bloc/search_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ecogrid_intelligence/di/di.dart';

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
  static const String search = '/search';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
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
      case climateDashboard:
        return _buildRoute(const ClimateDashboardScreen(), settings);
      case timeline:
        return _buildRoute(const TimelineScreen(), settings);
      case forecast:
        return _buildRoute(const ForecastScreen(), settings);
      case aiAnalysis:
        return _buildRoute(
          AiAnalysisScreen(
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
      case filter:
        return _buildRoute(
          FilterScreen(arguments: settings.arguments as Map<String, dynamic>?),
          settings,
        );
      case lgSettings:
        return _buildRoute(const LgSettingsScreen(), settings);
      case lgVisualization:
        return _buildRoute(const LgVisualizationScreen(), settings);
      case search:
        return _buildRoute(
          BlocProvider(
            create: (context) => sl<SearchBloc>(),
            child: const SearchScreen(),
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
      pageBuilder: (context, animation, secondaryAnimation) => page,
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
