import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:imaxip/models/category_model.dart';
import 'package:imaxip/models/history_item_model.dart';
import 'package:imaxip/models/live_stream_model.dart';
import 'package:imaxip/models/movie_model.dart';
import 'package:imaxip/models/series_model.dart';
import 'package:imaxip/providers/auth_provider.dart';
import 'package:imaxip/screens/content_list_screen.dart';
import 'package:imaxip/screens/favorites_screen.dart';
import 'package:imaxip/screens/movie_list_screen.dart';
import 'package:imaxip/screens/player_screen.dart';
import 'package:imaxip/screens/search_screen.dart';
import 'package:imaxip/screens/series_list_screen.dart';
import 'package:imaxip/services/api_service.dart';
import 'package:imaxip/services/database_helper.dart';
import 'package:imaxip/services/settings_service.dart';
import 'package:provider/provider.dart';
import 'package:imaxip/models/channel_model_for_db.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum CategoryView { list, grid }

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final ApiService _apiService = ApiService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final SettingsService _settingsService = SettingsService();

  CategoryView _categoryView = CategoryView.grid;

  late List<Future<List<Category>>> _categoryFutures;
  late Future<List<LiveStream>> _allLiveStreamsFuture;
  late Future<List<MovieModel>> _allMoviesFuture;
  late Future<List<SeriesModel>> _allSeriesFuture;
  late Future<List<HistoryItem>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadViewPreference();
  }

  void _loadViewPreference() async {
    final view = await _settingsService.getPreferredCategoryView();
    if (mounted) {
      setState(() {
        _categoryView = view == 'list' ? CategoryView.list : CategoryView.grid;
      });
    }
  }

  void _loadData() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final credentials = auth.getCredentials();

    setState(() {
      _historyFuture = _dbHelper.getHistory();
    });

    if (credentials['serverUrl']!.isEmpty) {
      _categoryFutures = [Future.value([]), Future.value([]), Future.value([])];
      _allLiveStreamsFuture = Future.value([]);
      _allMoviesFuture = Future.value([]);
      _allSeriesFuture = Future.value([]);
      return;
    }

    final serverUrl = credentials['serverUrl']!;
    final username = credentials['username']!;
    final password = credentials['password']!;

    _categoryFutures = [
      _apiService.getLiveCategories(serverUrl: serverUrl, username: username, password: password).then((list) => list.map((item) => Category.fromJson(item)).toList()),
      _apiService.getVodCategories(serverUrl: serverUrl, username: username, password: password).then((list) => list.map((item) => Category.fromJson(item)).where((category) => !category.categoryName.toUpperCase().contains('DİZİ')).toList()),
      _apiService.getSeriesCategories(serverUrl: serverUrl, username: username, password: password).then((list) => list.map((item) => Category.fromJson(item)).where((category) => !category.categoryName.toUpperCase().contains('FİLM')).toList()),
    ];

    // Bu future'lar arama ekranı için hala gerekli
    _allLiveStreamsFuture = _apiService.getAllLiveStreams(serverUrl: serverUrl, username: username, password: password).then((list) => list.map((item) => LiveStream.fromJson(item)).toList());
    _allMoviesFuture = _apiService.getAllMovies(serverUrl: serverUrl, username: username, password: password).then((list) => list.map((item) => MovieModel.fromJson(item)).toList());
    _allSeriesFuture = _apiService.getSeries(serverUrl: serverUrl, username: username, password: password).then((list) => list.map((item) => SeriesModel.fromJson(item)).toList());
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _toggleCategoryView() {
    setState(() {
      _categoryView = _categoryView == CategoryView.list ? CategoryView.grid : CategoryView.list;
    });
    _settingsService.setPreferredCategoryView(_categoryView == CategoryView.grid ? 'grid' : 'list');
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final username = authProvider.userInfo?.username ?? 'Kullanıcı';

    return Scaffold(
      appBar: AppBar(
        title: Text('Hoş Geldin, $username'),
        actions: [
          IconButton(icon: const Icon(Icons.search), tooltip: 'Arama Yap', onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => SearchScreen(
              allLiveStreamsFuture: _allLiveStreamsFuture,
              allMoviesFuture: _allMoviesFuture,
              allSeriesFuture: _allSeriesFuture,
            ),
            ),
            );
          },
          ),
          IconButton(icon: const Icon(Icons.star), tooltip: 'Favorilerim', onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const FavoritesScreen())).then((_) => _loadData());
          },
          ),
          IconButton(
            icon: Icon(_categoryView == CategoryView.list ? Icons.grid_view : Icons.view_list),
            tooltip: 'Görünümü Değiştir',
            onPressed: _toggleCategoryView,
          ),
          IconButton(icon: const Icon(Icons.logout), tooltip: 'Çıkış Yap', onPressed: () => authProvider.logout())
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContinueWatchingSection(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              child: Text("Kategoriler", style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
            ),
            _buildCategoriesSection(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.live_tv), label: 'Canlı TV'),
          BottomNavigationBarItem(icon: Icon(Icons.movie), label: 'Filmler'),
          BottomNavigationBarItem(icon: Icon(Icons.tv), label: 'Diziler'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.blueGrey[900]?.withOpacity(0.95),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildContinueWatchingSection() {
    return FutureBuilder<List<HistoryItem>>(
      future: _historyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasError) {
          return Padding(padding: EdgeInsets.all(16.w), child: Text("İzleme geçmişi yüklenirken hata oluştu: ${snapshot.error}"));
        }
        final history = snapshot.data!.where((item) => item.totalDuration > 0 && item.lastPosition / item.totalDuration < 0.95).toList();
        if (history.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: EdgeInsets.all(12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("İzlemeye Devam Et", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 10.h),
              SizedBox(
                height: 130.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final item = history[index];
                    return FocusableHistoryCard(
                      item: item,
                      onTap: () {
                        final content = ChannelForDB.fromHistory(item);
                        final auth = Provider.of<AuthProvider>(context, listen: false);
                        final credentials = auth.getCredentials();
                        final serverUrl = credentials['serverUrl']!;
                        final username = credentials['username']!;
                        final password = credentials['password']!;
                        String url;
                        if (item.mediaType == 'movie') {
                          url = '$serverUrl/movie/$username/$password/${item.streamId}.${content.containerExtension}';
                        } else {
                          url = '$serverUrl/series/$username/$password/${item.streamId}.${content.containerExtension}';
                        }
                        Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerScreen(
                          streamUrl: url,
                          content: content,
                          startPosition: Duration(seconds: item.lastPosition.toInt()),
                        ),
                        )).then((_) => _loadData());
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoriesSection() {
    return FutureBuilder<List<Category>>(
      future: _categoryFutures[_selectedIndex],
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.amber));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Padding(
            padding: EdgeInsets.all(20.w),
            child: const Text('Bu bölümde kategori bulunamadı.'),
          ));
        }

        final categories = snapshot.data!;

        if (_categoryView == CategoryView.grid) {
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.all(12.w),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 140.w,
              childAspectRatio: 2.w,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return FocusableCategoryCard(
                category: category,
                autofocus: index == 0,
                onTap: () {
                  if (_selectedIndex == 0) {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ContentListScreen(categoryId: category.categoryId, categoryName: category.categoryName)));
                  } else if (_selectedIndex == 1) {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => MovieListScreen(categoryId: category.categoryId, categoryName: category.categoryName)));
                  } else if (_selectedIndex == 2) {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => SeriesListScreen(categoryId: category.categoryId, categoryName: category.categoryName),
                    ));
                  }
                },
              );
            },
          );
        } else {
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return FocusableCategoryListItem(
                category: category,
                autofocus: index == 0,
                onTap: () {
                  if (_selectedIndex == 0) {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ContentListScreen(categoryId: category.categoryId, categoryName: category.categoryName)));
                  } else if (_selectedIndex == 1) {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => MovieListScreen(categoryId: category.categoryId, categoryName: category.categoryName)));
                  } else if (_selectedIndex == 2) {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => SeriesListScreen(categoryId: category.categoryId, categoryName: category.categoryName),
                    ));
                  }
                },
              );
            },
          );
        }
      },
    );
  }
}

class FocusableHistoryCard extends StatefulWidget {
  final HistoryItem item;
  final VoidCallback onTap;
  const FocusableHistoryCard({super.key, required this.item, required this.onTap});

  @override
  State<FocusableHistoryCard> createState() => _FocusableHistoryCardState();
}

class _FocusableHistoryCardState extends State<FocusableHistoryCard> {
  bool _isFocused = false;
  @override
  Widget build(BuildContext context) {
    final progress = widget.item.totalDuration > 0 ? widget.item.lastPosition / widget.item.totalDuration : 0.0;
    return AnimatedScale(scale: _isFocused ? 1.05 : 1.0, duration: const Duration(milliseconds: 200), child: Container(
      width: 100.w,
      margin: EdgeInsets.only(right: 12.w),
      child: InkWell(onTap: widget.onTap, onFocusChange: (hasFocus) { setState(() { _isFocused = hasFocus; }); }, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Card(elevation: _isFocused ? 12 : 4, clipBehavior: Clip.antiAlias, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r), side: BorderSide(color: _isFocused ? Colors.amber : Colors.transparent, width: 2.0)), child: AspectRatio(aspectRatio: 2 / 3, child: Image.network(widget.item.streamIcon ?? '', fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.movie)))))),
        SizedBox(height: 4.h),
        Text(widget.item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10.sp)),
        SizedBox(height: 4.h),
        LinearProgressIndicator(value: progress, backgroundColor: Colors.grey.shade700, color: Colors.amber, minHeight: 3.h)],
      ),
      ),
    ),
    );
  }
}

class FocusableCategoryListItem extends StatefulWidget {
  final Category category;
  final VoidCallback onTap;
  final bool autofocus;
  const FocusableCategoryListItem({super.key, required this.category, required this.onTap, this.autofocus = false});

  @override
  State<FocusableCategoryListItem> createState() => _FocusableCategoryListItemState();
}

class _FocusableCategoryListItemState extends State<FocusableCategoryListItem> {
  bool _isFocused = false;
  @override
  Widget build(BuildContext context) {
    final parts = widget.category.categoryName.split('•');
    String countryCode = '';
    String emoji = '';
    String mainText = widget.category.categoryName;
    if (parts.length > 1) {
      countryCode = parts[0].trim();
      mainText = parts.last.trim();
      if (parts.length > 2) {
        emoji = parts[1].trim();
      }
    }
    return Padding(padding: EdgeInsets.symmetric(vertical: 4.h), child: AnimatedScale(scale: _isFocused ? 1.02 : 1.0, duration: const Duration(milliseconds: 200), child: InkWell(autofocus: widget.autofocus, onFocusChange: (hasFocus) { setState(() { _isFocused = hasFocus; }); }, onTap: widget.onTap, child: Container(
      padding: EdgeInsets.symmetric(vertical: 5.h, horizontal: 5.w),
      decoration: BoxDecoration(color: _isFocused ? Colors.blueGrey.shade700 : Colors.blueGrey.shade800, borderRadius: BorderRadius.circular(8.r), border: Border.all(color: _isFocused ? Colors.amber : Colors.transparent, width: 2.0)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
        if (countryCode.isNotEmpty) Text("$countryCode -", style: TextStyle(color: Colors.white70, fontSize: 8.sp)),
        if (countryCode.isNotEmpty) SizedBox(width: 6.w),
        if (emoji.isNotEmpty) Text(emoji, style: TextStyle(fontSize: 10.sp)),
        if (emoji.isNotEmpty) SizedBox(width: 6.w),
        Expanded(child: Text(mainText, style: TextStyle(color: Colors.white, fontSize: 7.sp, fontWeight: FontWeight.bold))),
        Icon(Icons.chevron_right, color: Colors.white70, size: 18.sp)],
      ),
    ),
    ),
    ),
    );
  }
}

class FocusableCategoryCard extends StatefulWidget {
  final Category category;
  final VoidCallback onTap;
  final bool autofocus;
  const FocusableCategoryCard({super.key, required this.category, required this.onTap, this.autofocus = false});

  @override
  State<FocusableCategoryCard> createState() => _FocusableCategoryCardState();
}

class _FocusableCategoryCardState extends State<FocusableCategoryCard> {
  bool _isFocused = false;
  @override
  Widget build(BuildContext context) {
    final parts = widget.category.categoryName.split('•');
    String mainText = widget.category.categoryName.replaceAll("•", "").trim();
    String emoji = '';
    if (parts.length > 1 && parts[1].trim().length < 3 && parts[1].trim().isNotEmpty) {
      emoji = parts[1].trim();
    }
    return AnimatedScale(
      scale: _isFocused ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Card(
        elevation: _isFocused ? 12 : 4,
        color: _isFocused ? Colors.blueGrey.shade700 : Colors.blueGrey.shade800,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r), side: BorderSide(color: _isFocused ? Colors.amber : Colors.transparent, width: 2.0)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          autofocus: widget.autofocus,
          onFocusChange: (hasFocus) { setState(() { _isFocused = hasFocus; }); },
          onTap: widget.onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (emoji.isNotEmpty)
                  Text(emoji, style: TextStyle(fontSize: 18.sp)),
                if (emoji.isNotEmpty)
                  SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    mainText,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 7.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}