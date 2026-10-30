import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../services/news_service.dart';
import '../services/notification_service.dart';
import '../services/saved_news_service.dart';

import 'news_screen.dart';
import 'profile_screen.dart';
import 'saved_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  String selectedLocation = 'Select Location';

  final TextEditingController searchController = TextEditingController();

  final NewsService newsService = NewsService();
  final SavedNewsService savedNewsService = SavedNewsService();

  List<Map<String, dynamic>> localNews = [];
  List<Map<String, dynamic>> savedNews = [];
  List<Map<String, dynamic>> searchResults = [];

  bool isLoadingNews = false;

  final List<String> locations = [
    'Hyderabad',
    'Vijayawada',
    'Visakhapatnam',
    'Vizianagaram',
    'Tirupati',
    'Warangal',
    'Guntur',
    'Nellore',
    'Kurnool',
    'Rajahmundry',
    'Kakinada',
    'Bengaluru',
    'Chennai',
    'Mumbai',
    'Delhi',
    'Pune',
    'Kolkata',
  ];

  List<Widget> get pages => [
    HomeContent(
      location: selectedLocation,
      searchController: searchController,
      localNews: localNews,
      searchResults: searchResults,
      isLoadingNews: isLoadingNews,
      onLocationTap: showLocationSelector,
      onSeeAll: goToNews,
      savedNews: savedNews,
      onToggleSave: toggleSaveNews,
      onSearch: performSearch,
    ),
    const NewsScreen(),
    SavedScreen(savedNews: savedNews, onRemove: toggleSaveNews),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    loadSavedNews();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // SAVED NEWS
  // ============================================================

  Future<void> loadSavedNews() async {
    try {
      final data = await savedNewsService.getSavedNews();

      if (!mounted) return;

      setState(() {
        savedNews = data;
      });
    } catch (_) {}
  }

  Future<void> toggleSaveNews(Map<String, dynamic> article) async {
    final url = article['url']?.toString() ?? '';

    if (url.isEmpty) return;

    setState(() {
      final alreadySaved = savedNews.any(
        (saved) => saved['url']?.toString() == url,
      );

      if (alreadySaved) {
        savedNews.removeWhere((saved) => saved['url']?.toString() == url);
      } else {
        savedNews.add(article);
      }
    });

    await savedNewsService.saveNews(savedNews);
  }

  // ============================================================
  // SEARCH NEWS
  // ============================================================

  Future<void> performSearch(String query) async {
    final cleanQuery = query.trim();

    if (cleanQuery.isEmpty) return;

    try {
      final results = await newsService.searchNews(cleanQuery);

      if (!mounted) return;

      setState(() {
        searchResults = results;
      });
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to search news')));
    }
  }

  // ============================================================
  // LOCAL NEWS
  // ============================================================

  Future<void> loadLocalNews(String location) async {
    if (location == 'Select Location') return;

    setState(() {
      isLoadingNews = true;
      localNews = [];
    });

    try {
      final news = await newsService.getLocalNews(location);

      if (!mounted) return;

      setState(() {
        localNews = news;
        isLoadingNews = false;
      });

      if (news.isNotEmpty) {
        await NotificationService.showNotification(
          title: 'New Local News',
          body: 'New news is available for $location.',
        );
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoadingNews = false;
        localNews = [];
      });
    }
  }

  // ============================================================
  // CURRENT LOCATION
  // ============================================================

  Future<void> useCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable location services.')),
        );

        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission was not granted.')),
        );

        return;
      }

      final position = await Geolocator.getCurrentPosition();

      final city = await getCityFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      setState(() {
        selectedLocation = city;
      });

      Navigator.of(context).pop();

      await loadLocalNews(city);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to detect your current location.'),
        ),
      );
    }
  }

  // ============================================================
  // GET CITY
  // ============================================================

  Future<String> getCityFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    if (kIsWeb) {
      try {
        final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse'
          '?format=json'
          '&lat=$latitude'
          '&lon=$longitude'
          '&zoom=10'
          '&addressdetails=1',
        );

        final response = await http.get(
          url,
          headers: {'User-Agent': 'LocalNewsAlertsApp/1.0'},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          final address = data['address'];

          if (address != null) {
            return address['city']?.toString() ??
                address['town']?.toString() ??
                address['municipality']?.toString() ??
                address['county']?.toString() ??
                'Unknown Location';
          }
        }
      } catch (_) {}
    } else {
      try {
        final placemarks = await placemarkFromCoordinates(latitude, longitude);

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;

          return place.locality ??
              place.subAdministrativeArea ??
              place.administrativeArea ??
              'Unknown Location';
        }
      } catch (_) {}
    }

    return 'Unknown Location';
  }

  // ============================================================
  // LOCATION SELECTOR
  // ============================================================

  void showLocationSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String locationSearch = '';

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filteredLocations = locations
                .where(
                  (location) => location.toLowerCase().contains(
                    locationSearch.toLowerCase(),
                  ),
                )
                .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.82,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFEAF4FF), Color(0xFFF5EEFF)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Color(0xFF8B7FD6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  const SizedBox(height: 22),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 22),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Choose your location',
                        style: TextStyle(
                          color: Color(0xFF202631),
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 22),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Get local news and updates around you',
                        style: TextStyle(
                          color: Color(0xFF737B89),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GestureDetector(
                      onTap: useCurrentLocation,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4D8DFF), Color(0xFF7656E8)],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF5D70E8,
                              ).withValues(alpha: 0.25),
                              blurRadius: 15,
                              offset: const Offset(0, 7),
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.my_location_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Use Current Location',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Automatically detect your city',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      onChanged: (value) {
                        setSheetState(() {
                          locationSearch = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search city...',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF6C4DFF),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 22),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Popular Locations',
                        style: TextStyle(
                          color: Color(0xFF303743),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filteredLocations.length,
                      itemBuilder: (context, index) {
                        final city = filteredLocations[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: const Color(0xFFE3E7F3)),
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFDDF1FF),
                                    Color(0xFFE9E2FF),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.location_on_rounded,
                                color: Color(0xFF6655DD),
                              ),
                            ),
                            title: Text(
                              city,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFF8B93A1),
                            ),
                            onTap: () async {
                              setState(() {
                                selectedLocation = city;
                              });

                              Navigator.of(context).pop();

                              await loadLocalNews(city);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void goToNews() {
    setState(() {
      selectedIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      body: IndexedStack(index: selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        height: 72,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE9E3FF),
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF6548E8)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.newspaper_outlined),
            selectedIcon: Icon(
              Icons.newspaper_rounded,
              color: Color(0xFF6548E8),
            ),
            label: 'News',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border_rounded),
            selectedIcon: Icon(
              Icons.bookmark_rounded,
              color: Color(0xFF6548E8),
            ),
            label: 'Saved',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: Color(0xFF6548E8)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ================================================================
// HOME CONTENT
// ================================================================

class HomeContent extends StatelessWidget {
  final String location;
  final TextEditingController searchController;

  final List<Map<String, dynamic>> localNews;
  final List<Map<String, dynamic>> searchResults;

  final bool isLoadingNews;

  final VoidCallback onLocationTap;
  final VoidCallback onSeeAll;

  final List<Map<String, dynamic>> savedNews;

  final Future<void> Function(Map<String, dynamic> article) onToggleSave;

  final Future<void> Function(String query) onSearch;

  const HomeContent({
    super.key,
    required this.location,
    required this.searchController,
    required this.localNews,
    required this.searchResults,
    required this.isLoadingNews,
    required this.onLocationTap,
    required this.onSeeAll,
    required this.savedNews,
    required this.onToggleSave,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE8F3FF), Color(0xFFF2EDFF), Color(0xFFF9FAFF)],
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _header(context)),

            SliverToBoxAdapter(child: _introSection()),

            SliverToBoxAdapter(child: _locationCard()),

            SliverToBoxAdapter(child: _searchBar()),

            SliverToBoxAdapter(child: _quickUpdates()),

            SliverToBoxAdapter(child: _breakingNews()),

            SliverToBoxAdapter(child: _latestHeader()),

            if (searchController.text.isNotEmpty && searchResults.isNotEmpty)
              SliverToBoxAdapter(child: _searchHeader()),

            if (searchController.text.isNotEmpty && searchResults.isNotEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(
                        left: 18,
                        right: 18,
                        bottom: 14,
                      ),
                      child: _newsCard(searchResults[index]),
                    );
                  },
                  childCount: searchResults.length > 5
                      ? 5
                      : searchResults.length,
                ),
              ),

            if (searchController.text.isEmpty) _buildLocalNewsList(),

            const SliverToBoxAdapter(child: SizedBox(height: 25)),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 15, 18, 5),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4D8DFF), Color(0xFF7455E8)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6756E8).withValues(alpha: 0.22),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.newspaper_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LOCAL NEWS',
                  style: TextStyle(
                    color: Color(0xFF6B54D8),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'News & Alerts',
                  style: TextStyle(
                    color: Color(0xFF202631),
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE1E5F2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF5D4AD2),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INTRO
  // ============================================================

  Widget _introSection() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Good Morning 👋',
            style: TextStyle(
              color: Color(0xFF777F8E),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'What’s happening near you?',
            style: TextStyle(
              color: Color(0xFF1E2530),
              fontSize: 25,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Stay informed with the latest local updates.',
            style: TextStyle(color: Color(0xFF747D8C), fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOCATION CARD
  // ============================================================

  Widget _locationCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: GestureDetector(
        onTap: onLocationTap,
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF477FFF), Color(0xFF7655E8)],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5E64E7).withValues(alpha: 0.25),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YOUR LOCATION',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit_location_alt_rounded,
                  color: Colors.white,
                  size: 19,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C4DFF).withValues(alpha: 0.07),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: TextField(
          controller: searchController,
          onSubmitted: onSearch,
          decoration: InputDecoration(
            hintText: 'Search local news...',
            hintStyle: const TextStyle(color: Color(0xFF9AA1AE), fontSize: 13),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: Color(0xFF6C4DFF),
            ),
            suffixIcon: IconButton(
              onPressed: () {
                onSearch(searchController.text);
              },
              icon: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4D8DFF), Color(0xFF7455E8)],
                  ),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // QUICK UPDATES
  // ============================================================

  Widget _quickUpdates() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Updates',
            style: TextStyle(
              color: Color(0xFF202631),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 11),

          SizedBox(
            height: 105,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _quickCard(
                  icon: Icons.wb_sunny_rounded,
                  title: 'Weather',
                  subtitle: 'Local forecast',
                  colors: const [Color(0xFFFFB84D), Color(0xFFFF7E5F)],
                ),

                _quickCard(
                  icon: Icons.warning_amber_rounded,
                  title: 'Alerts',
                  subtitle: 'Important updates',
                  colors: const [Color(0xFFFF667A), Color(0xFFE84570)],
                ),

                _quickCard(
                  icon: Icons.event_rounded,
                  title: 'Events',
                  subtitle: 'Around your city',
                  colors: const [Color(0xFF4D8DFF), Color(0xFF6954E8)],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> colors,
  }) {
    return Container(
      width: 145,
      margin: const EdgeInsets.only(right: 11),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.20),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 25),

          const Spacer(),

          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, fontSize: 9.5),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BREAKING NEWS
  // ============================================================

  Widget _breakingNews() {
    if (localNews.isEmpty) {
      return const SizedBox.shrink();
    }

    final article = localNews.first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 6),
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF5964), Color(0xFFFF7A45)],
          ),
          borderRadius: BorderRadius.circular(21),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF5964).withValues(alpha: 0.22),
              blurRadius: 17,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'BREAKING',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),

                const Spacer(),

                const Icon(
                  Icons.flash_on_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              _title(article),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                height: 1.25,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              _description(article).isEmpty
                  ? 'Latest update from $location'
                  : _description(article),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LATEST HEADER
  // ============================================================

  Widget _latestHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 12),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Latest Local News',
                  style: TextStyle(
                    color: Color(0xFF202631),
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Fresh updates from your area',
                  style: TextStyle(color: Color(0xFF838B99), fontSize: 11),
                ),
              ],
            ),
          ),

          TextButton(
            onPressed: onSeeAll,
            child: const Text(
              'See All',
              style: TextStyle(
                color: Color(0xFF6548E8),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH HEADER
  // ============================================================

  Widget _searchHeader() {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(18, 5, 18, 12),
        child: Text(
          'Search Results',
          style: TextStyle(
            color: Color(0xFF202631),
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOCAL NEWS LIST
  // ============================================================

  Widget _buildLocalNewsList() {
    if (isLoadingNews) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(35),
          child: Center(
            child: CircularProgressIndicator(color: Color(0xFF6C4DFF)),
          ),
        ),
      );
    }

    if (location == 'Select Location') {
      return SliverToBoxAdapter(
        child: _emptyState(
          icon: Icons.location_on_outlined,
          title: 'Select your location',
          message: 'Choose your city to get local news and updates.',
          buttonText: 'Choose Location',
          onPressed: onLocationTap,
        ),
      );
    }

    if (localNews.isEmpty) {
      return SliverToBoxAdapter(
        child: _emptyState(
          icon: Icons.newspaper_outlined,
          title: 'No local news available',
          message: 'We could not find local news for $location right now.',
          buttonText: 'Search Again',
          onPressed: () => onSearch(location),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        return Padding(
          padding: const EdgeInsets.only(left: 18, right: 18, bottom: 14),
          child: _newsCard(localNews[index]),
        );
      }, childCount: localNews.length > 10 ? 10 : localNews.length),
    );
  }

  // ============================================================
  // NEWS CARD
  // ============================================================

  Widget _newsCard(Map<String, dynamic> article) {
    final title = _title(article);
    final description = _description(article);
    final source = _source(article);
    final published = _time(article);
    final url = article['url']?.toString() ?? '';

    final isSaved = savedNews.any(
      (saved) => saved['url']?.toString() == url && url.isNotEmpty,
    );

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF4F7FF)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE5FF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C4DFF).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFDDF1FF), Color(0xFFE9E2FF)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'LOCAL',
                    style: TextStyle(
                      color: Color(0xFF5B4BDB),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                const SizedBox(width: 9),

                Expanded(
                  child: Text(
                    source,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF8A93A0),
                      fontSize: 11,
                    ),
                  ),
                ),

                IconButton(
                  onPressed: () => onToggleSave(article),
                  icon: Icon(
                    isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: isSaved
                        ? const Color(0xFF6C4DFF)
                        : const Color(0xFF697382),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 5),

            GestureDetector(
              onTap: () => _openArticle(url),
              child: Text(
                title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF202631),
                  fontSize: 17,
                  height: 1.28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),

              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF697382),
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ],

            const SizedBox(height: 13),

            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 15,
                  color: Color(0xFF929AA7),
                ),

                const SizedBox(width: 5),

                Text(
                  published,
                  style: const TextStyle(
                    color: Color(0xFF929AA7),
                    fontSize: 11,
                  ),
                ),

                const Spacer(),

                GestureDetector(
                  onTap: () => _openArticle(url),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 19,
                    color: Color(0xFF6C4DFF),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String message,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(18, 5, 18, 5),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF0F3FF)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE5FF)),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFDDF1FF), Color(0xFFE9E2FF)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: const Color(0xFF6C4DFF), size: 33),
          ),

          const SizedBox(height: 14),

          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF202631),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF707987),
              fontSize: 12.5,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 17),

          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C4DFF),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _title(Map<String, dynamic> article) {
    final value = article['title']?.toString().trim() ?? '';

    if (value.isEmpty || value == 'null') {
      return 'Local News Update';
    }

    return value;
  }

  String _description(Map<String, dynamic> article) {
    final value = article['description']?.toString().trim() ?? '';

    if (value.isEmpty || value == 'null') {
      return '';
    }

    return value;
  }

  String _source(Map<String, dynamic> article) {
    final source = article['source'];

    if (source is Map) {
      return source['name']?.toString() ?? 'News Source';
    }

    if (source != null) {
      return source.toString();
    }

    return 'News Source';
  }

  String _time(Map<String, dynamic> article) {
    final value =
        article['publishedAt']?.toString() ??
        article['published_at']?.toString() ??
        '';

    if (value.isEmpty) {
      return 'Latest update';
    }

    try {
      final date = DateTime.parse(value);

      final now = DateTime.now();

      final difference = now.difference(date);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes} min ago';
      }

      if (difference.inHours < 24) {
        return '${difference.inHours} hr ago';
      }

      if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      }

      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return 'Latest update';
    }
  }

  Future<void> _openArticle(String url) async {
    if (url.isEmpty) return;

    final uri = Uri.tryParse(url);

    if (uri == null) return;

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}
