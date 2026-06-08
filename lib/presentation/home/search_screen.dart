import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ecogrid_intelligence/config/theme/app_theme.dart';
import 'package:ecogrid_intelligence/config/theme/theme_controller.dart';
import 'package:ecogrid_intelligence/presentation/home/bloc/search_bloc.dart';
import 'package:ecogrid_intelligence/config/routes/app_routes.dart';
import 'package:ecogrid_intelligence/presentation/components/app_search_bar.dart';
import 'package:ecogrid_intelligence/presentation/components/atmospheric_globe_painter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SearchScreen extends StatefulWidget {
  final bool autoStartVoice;
  const SearchScreen({super.key, this.autoStartVoice = false});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<String> _recentSearches = [];
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (error) => print('Speech Error: ${error.errorMsg}'),
        onStatus: (status) => print('Speech Status: $status'),
      );
    } catch (e) {
      print('Speech init exception: $e');
    }
    if (mounted) {
      setState(() {});
      if (_speechEnabled && widget.autoStartVoice) {
        _startListening();
      }
    }
  }

  void _startListening() async {
    if (!_speechEnabled) {
      await _initSpeech();
      if (!_speechEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Voice search is not available. Please ensure microphone permissions are granted and restart the app.',
              ),
              backgroundColor: AppTheme.primary,
            ),
          );
        }
        return;
      }
    }
    await _speechToText.listen(
      onResult: (result) {
        if (mounted) {
          setState(() {
            _controller.text = result.recognizedWords;
          });
          context.read<SearchBloc>().add(
            SearchQueryChanged(result.recognizedWords),
          );
        }
      },
    );
    if (mounted) {
      setState(() {
        _isListening = true;
      });
    }
  }

  void _stopListening() async {
    await _speechToText.stop();
    if (mounted) {
      setState(() {
        _isListening = false;
      });
    }
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
    if (_isListening) _speechToText.stop();
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
        final isLight = !isDark;
        final screenWidth = MediaQuery.of(context).size.width;

        return Scaffold(
          backgroundColor: isLight
              ? const Color(0xFFEEF2F8)
              : const Color(0xFF08080F),
          body: Stack(
            children: [
              // Globe background, bottom right
              Positioned(
                bottom: -screenWidth * 0.4,
                right: -screenWidth * 0.4,
                width: screenWidth,
                height: screenWidth,
                child: isLight
                    ? const SizedBox.shrink()
                    : Opacity(
                        opacity: isDark ? 1.0 : 0.6,
                        child: FuturisticGlobeBackground(isDark: isDark),
                      ),
              ),
              // Global Glow Background
              Positioned.fill(
                child: isLight
                    ? const SizedBox.shrink()
                    : Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(0, -0.5),
                            radius: 1.2,
                            colors: [
                              const Color(
                                0xFF00C8FF,
                              ).withValues(alpha: isDark ? 0.15 : 0.08),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
              ),
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar Area
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                      child: Row(
                        children: [
                          isLight
                              ? Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFFF6FAFD),
                                        const Color(
                                          0xFFB3CFE5,
                                        ).withValues(alpha: 0.60),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF4A7FA7,
                                      ).withValues(alpha: 0.35),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF0A1931,
                                        ).withValues(alpha: 0.12),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      ),
                                      BoxShadow(
                                        color: const Color(
                                          0xFF4A7FA7,
                                        ).withValues(alpha: 0.15),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.arrow_back_ios_rounded,
                                      color: Color(0xFF1A3D63),
                                      size: 18,
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                )
                              : Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppTheme.cardBackground,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.arrow_back_ios_new,
                                      color: Color(0xFF00C8FF),
                                      size: 18,
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppSearchBar(
                              hintText: 'Search regions or power plants...',
                              readOnly: false,
                              controller: _controller,
                              isListening: _isListening,
                              onMicTap: () {
                                if (_isListening) {
                                  _stopListening();
                                } else {
                                  _startListening();
                                }
                              },
                              onClearTap: () {
                                _controller.clear();
                                context.read<SearchBloc>().add(
                                  const SearchCleared(),
                                );
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
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Content
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

  Color _getRegionColor(String region) {
    switch (region.toLowerCase()) {
      case 'india':
        return const Color(0xFF00C853);
      case 'europe':
        return const Color(0xFF4A90D9); // Blue
      case 'usa':
        return const Color(0xFFFF5252); // Red
      case 'china':
        return const Color(0xFFB388FF); // Bright Purple
      case 'africa':
        return const Color(0xFFE8A44A);
      case 'spain':
        return const Color(0xFFE75480);
      default:
        return const Color(0xFF00C8FF);
    }
  }

  Widget _buildEmptyState() {
    final isDark = ThemeController.instance.isDarkMode;
    final isLight = !isDark;
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
              style: TextStyle(
                color: isLight
                    ? const Color(0xFF6B80A0)
                    : AppTheme.textSecondary,
                fontSize: isLight ? 10 : 11,
                fontWeight: isLight ? FontWeight.w500 : FontWeight.w700,
                letterSpacing: isLight ? 0.8 : 2.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isLight ? 3 : 2,
            childAspectRatio: isLight ? 1.0 : 2.8,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: popularRegions.length,
          itemBuilder: (context, index) {
            final region = popularRegions[index];
            final rColor = _getRegionColor(region);
            return isLight
                ? GestureDetector(
                    onTap: () {
                      _controller.text = region;
                      context.read<SearchBloc>().add(
                        SearchQueryChanged(region),
                      );
                      setState(() {});
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFD6E8F8),
                            Color(0xFFB0CCF0),
                            Color(0xFF7AAEE0),
                            Color(0xFF4A82C8),
                          ],
                          stops: [0.0, 0.35, 0.70, 1.0],
                        ),
                        border: Border.all(
                          color: const Color(0xFF2A5298),
                          width: 1.2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x332A5298),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0x33FFFFFF),
                              border: Border.all(
                                color: const Color(0x662A5298),
                                width: 0.8,
                              ),
                            ),
                            child: Icon(Icons.public, color: rColor, size: 24),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            region,
                            style: const TextStyle(
                              color: Color(0xFF0D1F4A),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              letterSpacing: 0.2,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  )
                : InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      _controller.text = region;
                      context.read<SearchBloc>().add(
                        SearchQueryChanged(region),
                      );
                      setState(() {});
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: rColor.withValues(alpha: 0.4),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: rColor.withValues(alpha: 0.10),
                            blurRadius: 12,
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
                              child: Icon(
                                Icons.public,
                                color: rColor,
                                size: 20,
                              ),
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
              style: TextStyle(
                color: isLight
                    ? const Color(0xFF6B80A0)
                    : AppTheme.textSecondary,
                fontSize: isLight ? 10 : 11,
                fontWeight: isLight ? FontWeight.w500 : FontWeight.w700,
                letterSpacing: isLight ? 0.8 : 2.2,
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
                      color: isLight
                          ? const Color(0xFF6B80A0)
                          : const Color(0xFF00C8FF),
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
              child: GestureDetector(
                onTap: () {
                  _controller.text = search;
                  context.read<SearchBloc>().add(SearchQueryChanged(search));
                  setState(() {});
                },
                child: isLight
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          gradient: const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Color(0xFF1F4489),
                              Color(0xFF3567C0),
                              Color(0xFF4A7ED4),
                              Color(0xFF7AAEE0),
                            ],
                            stops: [0.0, 0.30, 0.65, 1.0],
                          ),
                          border: Border.all(
                            color: const Color(0x665A8CD2),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0x26FFFFFF),
                              ),
                              child: const Icon(
                                Icons.history_rounded,
                                color: Color(0xFFC5D8EE),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                search,
                                style: const TextStyle(
                                  color: Color(0xFFFFFFFF),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFF9BBCE0),
                              size: 18,
                            ),
                          ],
                        ),
                      )
                    : InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          _controller.text = search;
                          context.read<SearchBloc>().add(
                            SearchQueryChanged(search),
                          );
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
                              color: const Color(
                                0xFF00C8FF,
                              ).withValues(alpha: 0.3),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF00C8FF,
                                ).withValues(alpha: 0.05),
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
                                  color: const Color(
                                    0xFF00C8FF,
                                  ).withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.history,
                                    color: Color(0xFF00C8FF),
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
                              const Icon(
                                Icons.chevron_right,
                                color: Color(0xFF00C8FF),
                                size: 20,
                              ),
                            ],
                          ),
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
