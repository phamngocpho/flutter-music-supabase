import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spotify/core/extensions/is_dark_mode.dart';
import 'package:spotify/presentation/search/bloc/search_cubit.dart';
import 'package:spotify/presentation/search/bloc/search_state.dart';
import 'package:spotify/domain/entities/song_entity.dart';
import 'package:spotify/shared/widgets/favorite_button.dart';
import 'package:spotify/presentation/song_player/pages/song_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({super.key});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late SearchCubit _searchCubit;
  List<Map<String, String>> _recentSearches = [];
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _searchCubit = SearchCubit();
    _searchFocusNode.addListener(_onSearchFocusChange);
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _removeOverlay();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchCubit.close();
    super.dispose();
  }

  void _onSearchFocusChange() {
    if (_searchFocusNode.hasFocus) {
      _showOverlay();
    } else {
      Future.delayed(const Duration(milliseconds: 200), () {
        _removeOverlay();
      });
    }
  }

  void _showOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 56),
          child: Material(
            elevation: 8,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            child: BlocProvider.value(
              value: _searchCubit,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                decoration: BoxDecoration(
                  color: context.isDarkMode ? const Color(0xff121212) : Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: BlocBuilder<SearchCubit, SearchState>(
                  builder: (context, state) {
                    if (_searchController.text.isEmpty) {
                      return _buildRecentSearches();
                    } else if (state is SearchLoading) {
                      return const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    } else if (state is SearchLoaded) {
                      if (state.songs.isEmpty) {
                        return _buildEmptyState();
                      }
                      return _buildSearchResults(state.songs);
                    } else if (state is SearchError) {
                      return _buildErrorState(state.message);
                    }
                    return _buildRecentSearches();
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final searches = prefs.getStringList('recent_searches') ?? [];
    setState(() {
      _recentSearches = searches
          .map((s) => Map<String, String>.from(jsonDecode(s)))
          .toList();
    });
  }

  Future<void> _saveRecentSearch(String query, SongEntity song) async {
    final search = {
      'query': query,
      'title': song.title,
      'artist': song.artist,
      'coverUrl': song.coverUrl ?? '',
    };

    _recentSearches.removeWhere((s) =>
    s['title'] == search['title'] && s['artist'] == search['artist']);

    _recentSearches.insert(0, search);

    if (_recentSearches.length > 10) {
      _recentSearches = _recentSearches.sublist(0, 10);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'recent_searches',
      _recentSearches.map((s) => jsonEncode(s)).toList(),
    );

    setState(() {});
  }

  Future<void> _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searches');
    setState(() {
      _recentSearches = [];
    });
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      _searchCubit.clearSearch();
      return;
    }
    _searchCubit.searchSongs(query);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _searchCubit,
      child: CompositedTransformTarget(
        link: _layerLink,
        child: Container(
          margin: const EdgeInsets.all(16),
          height: 48,
          decoration: BoxDecoration(
            color: context.isDarkMode
                ? const Color(0xff1E1E1E)
                : const Color(0xffF0F0F0),
            borderRadius: BorderRadius.circular(24),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            style: TextStyle(
              color: context.isDarkMode ? Colors.white : Colors.black,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: 'What do you want to play?',
              hintStyle: TextStyle(
                color: context.isDarkMode
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.black.withValues(alpha: 0.5),
                fontSize: 15,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: context.isDarkMode
                    ? Colors.white.withValues(alpha: 0.7)
                    : Colors.black.withValues(alpha: 0.7),
                size: 22,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: Icon(
                  Icons.clear,
                  color: context.isDarkMode
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.black.withValues(alpha: 0.7),
                  size: 20,
                ),
                onPressed: () {
                  _searchController.clear();
                  _searchCubit.clearSearch();
                  setState(() {});
                  _showOverlay();
                },
              )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            onChanged: (value) {
              setState(() {});
              if (value.trim().isNotEmpty) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == value) {
                    _performSearch(value);
                  }
                });
              } else {
                _searchCubit.clearSearch();
              }
            },
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                _performSearch(value);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSearches() {
    if (_recentSearches.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search,
              size: 48,
              color: context.isDarkMode
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'Search for songs and artists',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: context.isDarkMode
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.black.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent searches',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _clearRecentSearches();
                    _showOverlay();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Clear',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.isDarkMode
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.black.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentSearches.length,
            itemBuilder: (context, index) {
              final search = _recentSearches[index];
              return InkWell(
                onTap: () {
                  _searchController.text = search['query']!;
                  _performSearch(search['query']!);
                  _searchFocusNode.unfocus();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: context.isDarkMode
                              ? const Color(0xff282828)
                              : const Color(0xffE0E0E0),
                        ),
                        child: search['coverUrl']!.isNotEmpty
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            search['coverUrl']!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.music_note,
                                size: 20,
                                color: context.isDarkMode
                                    ? Colors.white.withValues(alpha: 0.5)
                                    : Colors.black.withValues(alpha: 0.5),
                              );
                            },
                          ),
                        )
                            : Icon(
                          Icons.music_note,
                          size: 20,
                          color: context.isDarkMode
                              ? Colors.white.withValues(alpha: 0.5)
                              : Colors.black.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              search['title']!,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: context.isDarkMode ? Colors.white : Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Song • ${search['artist']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.isDarkMode
                                    ? Colors.white.withValues(alpha: 0.6)
                                    : Colors.black.withValues(alpha: 0.6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.music_off,
            size: 48,
            color: context.isDarkMode
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'No results found',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: context.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try different keywords',
            style: TextStyle(
              fontSize: 13,
              color: context.isDarkMode
                  ? Colors.white.withValues(alpha: 0.6)
                  : Colors.black.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          const Text(
            'Error',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: context.isDarkMode
                  ? Colors.white.withValues(alpha: 0.6)
                  : Colors.black.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(List<SongEntity> songs) {
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        return InkWell(
          onTap: () async {
            await _saveRecentSearch(_searchController.text, songs[index]);
            _searchFocusNode.unfocus();
            _removeOverlay();
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SongPlayerPage(
                    songEntity: songs[index],
                  ),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: context.isDarkMode
                        ? const Color(0xff282828)
                        : const Color(0xffE0E0E0),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: songs[index].coverUrl != null
                        ? Image.network(
                      songs[index].coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.music_note,
                          size: 20,
                          color: context.isDarkMode
                              ? Colors.white.withValues(alpha: 0.5)
                              : Colors.black.withValues(alpha: 0.5),
                        );
                      },
                    )
                        : Icon(
                      Icons.music_note,
                      size: 20,
                      color: context.isDarkMode
                          ? Colors.white.withValues(alpha: 0.5)
                          : Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        songs[index].title,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: context.isDarkMode ? Colors.white : Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        songs[index].artist,
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          color: context.isDarkMode
                              ? Colors.white.withValues(alpha: 0.6)
                              : Colors.black.withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FavoriteButton(
                  songEntity: songs[index],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}