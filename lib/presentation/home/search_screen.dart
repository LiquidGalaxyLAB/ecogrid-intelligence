import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/theme/app_theme.dart';
import '../../config/theme/theme_controller.dart';
import 'bloc/search_bloc.dart';
import '../../config/routes/app_routes.dart';
import '../components/app_search_bar.dart';
import '../../di/service_di.dart';
import '../../service/speech_to_text_service.dart';

class SearchScreen extends StatefulWidget {
  final bool autoStartVoice;
  const SearchScreen({super.key, this.autoStartVoice = false});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<String> _recentSearches = [];
  bool _isListening = false;
  SpeechToTextService get _stt => sl<SpeechToTextService>();
  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    if (widget.autoStartVoice) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startListening());
    }
  }

  void _startListening() async {
    await _stt.startListening(
      onResult: (words) {
        if (mounted) {
          setState(() => _controller.text = words);
          context.read<SearchBloc>().add(SearchQueryChanged(words));
        }
      },
      onListening: (listening) {
        if (mounted) setState(() => _isListening = listening);
      },
    );
  }

  void _stopListening() async {
    await _stt.stopListening(
      onListening: (listening) {
        if (mounted) setState(() => _isListening = listening);
      },
    );
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recent_searches') ?? [];
    });
  }

  Future<void> _addRecentSearch(String search) async {
    if (search.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    List<String> searches = prefs.getStringList('recent_searches') ?? [];
    searches.remove(search);
    searches.insert(0, search);
    if (searches.length > 5) {
      searches = searches.sublist(0, 5);
    }
    await prefs.setStringList('recent_searches', searches);
    if (mounted) {
      setState(() {
        _recentSearches = searches;
      });
    }
  }

  Future<void> _clearAllRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searches');
    if (mounted) {
      setState(() {
        _recentSearches = [];
      });
    }
  }

  @override
  void dispose() {
    if (_isListening) _stt.stopListening();
    _controller.dispose();
    super.dispose();
  }

  IconData _plantTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'nuclear':
        return Icons.science;
      case 'hydroelectric':
        return Icons.water;
      case 'solar':
        return Icons.wb_sunny;
      case 'wind':
        return Icons.air;
      case 'coal/thermal':
        return Icons.factory;
      case 'natural gas':
        return Icons.local_fire_department;
      default:
        return Icons.bolt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.themeModeNotifier,
      builder: (context, preset, _) {
        final isDark = ThemeController.instance.isDarkMode;
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        return Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: AppTheme.background,
          body: Stack(
            children: [
              Positioned(
                bottom: -screenWidth * 0.05,
                right: -screenWidth * 0.3,
                width: screenWidth * 1.35,
                height: screenWidth * 1.35,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..scale(-1.0, 1.0),
                  child: Image.asset(
                    isDark
                        ? 'assets/images/hero_globe_dark.png'
                        : 'assets/images/hero_globe_light.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.bottomRight,
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.5),
                      radius: 1.2,
                      colors: isDark
                          ? [
                              AppTheme.primary.withValues(alpha: 0.15),
                              Colors.transparent,
                            ]
                          : [
                              const Color(0xFF00C8FF).withValues(alpha: 0.12),
                              const Color(0xFF0066FF).withValues(alpha: 0.04),
                              Colors.transparent,
                            ],
                      stops: isDark ? null : const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                      child: AppSearchBar(
                        hintText: 'Search regions or power plants...',
                        readOnly: false,
                        controller: _controller,
                        isListening: _isListening,
                        onPrefixIconTap: () => Navigator.pop(context),
                        prefixIcon: Icons.arrow_back_ios_new,
                        onMicTap: () {
                          if (_isListening) {
                            _stopListening();
                          } else {
                            _startListening();
                          }
                        },
                        onClearTap: () {
                          _controller.clear();
                          context.read<SearchBloc>().add(const SearchCleared());
                          if (_isListening) _stopListening();
                          setState(() {});
                        },
                        onChanged: (query) {
                          context.read<SearchBloc>().add(
                            SearchQueryChanged(query),
                          );
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: BlocBuilder<SearchBloc, SearchState>(
                        builder: (context, state) {
                          if (state.query.isEmpty) {
                            return _buildEmptyState();
                          }
                          if (state.isSearching) {
                            return Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.primary,
                              ),
                            );
                          }
                          if (state.results.isEmpty &&
                              state.regionResults.isEmpty) {
                            return Center(
                              child: Text(
                                'No results found',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            );
                          }
                          return _buildResultsList(state);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getRegionColor(String region, bool isDark) {
    switch (region.toLowerCase()) {
      case 'india':
        return isDark ? const Color(0xFF00C853) : const Color(0xFF81C784);
      case 'europe':
        return isDark ? const Color(0xFF4A90D9) : const Color(0xFF90CAF9);
      case 'usa':
        return isDark ? const Color(0xFFFF5252) : const Color(0xFFEF9A9A);
      case 'china':
        return isDark ? const Color(0xFFB388FF) : const Color(0xFFB39DDB);
      case 'africa':
        return isDark ? const Color(0xFFE8A44A) : const Color(0xFFFFCC80);
      case 'spain':
        return isDark ? const Color(0xFFE75480) : const Color(0xFFF48FB1);
      default:
        return isDark ? const Color(0xFF00C8FF) : const Color(0xFF81D4FA);
    }
  }

  Widget _buildEmptyState() {
    final isDark = ThemeController.instance.isDarkMode;
    final popularRegions = [
      'India',
      'China',
      'Europe',
      'USA',
      'Africa',
      'Spain',
    ];
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'POPULAR REGIONS',
              style: AppTheme.labelSmall.copyWith(
                color: AppTheme.textSecondary,
                letterSpacing: 2.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.8,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: popularRegions.length,
          itemBuilder: (context, index) {
            final region = popularRegions[index];
            final rColor = _getRegionColor(region, isDark);
            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                _controller.text = region;
                context.read<SearchBloc>().add(SearchQueryChanged(region));
                setState(() {});
              },
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: rColor.withValues(alpha: isDark ? 0.4 : 0.8),
                    width: isDark ? 1.0 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: rColor.withValues(alpha: isDark ? 0.10 : 0.15),
                      blurRadius: isDark ? 12 : 8,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: rColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(Icons.public, color: rColor, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        region,
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'RECENT SEARCHES',
              style: AppTheme.labelSmall.copyWith(
                color: AppTheme.textSecondary,
                letterSpacing: 2.2,
              ),
            ),
            if (_recentSearches.isNotEmpty)
              InkWell(
                onTap: _clearAllRecentSearches,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Text(
                    'Clear All',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (_recentSearches.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No recent searches.',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
            ),
          )
        else
          ..._recentSearches.map(
            (search) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  _controller.text = search;
                  context.read<SearchBloc>().add(SearchQueryChanged(search));
                  setState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.history,
                            color: AppTheme.primary,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          search,
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildResultsList(SearchState state) {
    final totalItems = state.regionResults.length + state.results.length;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        if (index < state.regionResults.length) {
          final region = state.regionResults[index];
          return ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Icon(Icons.public, color: AppTheme.primary, size: 20),
            ),
            title: Text(
              region.displayName ?? region.name,
              style: AppTheme.bodyMedium,
            ),
            subtitle: Text('Region', style: AppTheme.caption),
            trailing: Icon(Icons.explore, color: AppTheme.primary, size: 20),
            onTap: () {
              _addRecentSearch(region.displayName ?? region.name);
              Navigator.pushReplacementNamed(
                context,
                AppRoutes.explore,
                arguments: {'region': region},
              );
            },
          );
        } else {
          final plantIndex = index - state.regionResults.length;
          final plant = state.results[plantIndex];
          return ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Icon(
                _plantTypeIcon(plant.primaryFuel.displayName),
                color: AppTheme.primary,
                size: 20,
              ),
            ),
            title: Text(plant.name, style: AppTheme.bodyMedium),
            subtitle: Text(
              '${plant.primaryFuel.displayName} • ${plant.countryLong ?? plant.country}',
              style: AppTheme.caption,
            ),
            trailing: Icon(Icons.chevron_right, color: AppTheme.textMuted),
            onTap: () {
              _addRecentSearch(plant.name);
              Navigator.pushReplacementNamed(
                context,
                AppRoutes.plantDetail,
                arguments: {'plant': plant},
              );
            },
          );
        }
      },
    );
  }
}
