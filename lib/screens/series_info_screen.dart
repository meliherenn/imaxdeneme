import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:imaxip/models/episode_model.dart';
import 'package:imaxip/models/series_model.dart';
import 'package:imaxip/providers/auth_provider.dart';
import 'package:imaxip/screens/player_screen.dart';
import 'package:imaxip/services/api_service.dart';
import 'package:imaxip/services/tmdb_service.dart';
import 'package:imaxip/models/tmdb_details_model.dart';
import 'package:provider/provider.dart';
import '../models/channel_model_for_db.dart';

class SeriesInfoScreen extends StatefulWidget {
  final SeriesModel series;

  const SeriesInfoScreen({super.key, required this.series});

  @override
  State<SeriesInfoScreen> createState() => _SeriesInfoScreenState();
}

class _SeriesInfoScreenState extends State<SeriesInfoScreen> {
  late Future<Map<String, List<EpisodeModel>>> _seasonsFuture;
  final ApiService _apiService = ApiService();

  final TmdbService _tmdbService = TmdbService();
  TmdbDetailsModel? _tmdbDetails;

  @override
  void initState() {
    super.initState();
    _loadXtreamData();
    _loadTmdbData();
  }

  void _loadXtreamData() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final credentials = auth.getCredentials();

    _seasonsFuture = _apiService
        .getSeriesInfo(
      serverUrl: credentials['serverUrl']!,
      username: credentials['username']!,
      password: credentials['password']!,
      seriesId: widget.series.seriesId,
    )
        .then((data) {
      final Map<String, List<EpisodeModel>> seasons = {};
      if (data.containsKey('episodes') && data['episodes'] != null) {
        final episodesData = data['episodes'] as Map<String, dynamic>;

        episodesData.forEach((seasonNumber, episodeList) {
          final episodes = (episodeList as List)
              .map((e) => EpisodeModel.fromJson(e))
              .toList();
          seasons[seasonNumber] = episodes;
        });
      }
      return seasons;
    });
  }

  Future<void> _loadTmdbData() async {
    final details = await _tmdbService.fetchDetails(
      name: widget.series.name,
      mediaType: 'tv',
    );
    if (mounted) {
      setState(() {
        _tmdbDetails = details;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, List<EpisodeModel>>>(
        future: _seasonsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.amber));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Bu diziye ait bölüm bulunamadı.'));
          }

          final seasons = snapshot.data!;
          final seasonKeys = seasons.keys.toList()..sort((a,b) => int.parse(a).compareTo(int.parse(b)));

          final backdropUrl = _tmdbDetails?.fullBackdropUrl ?? widget.series.cover ?? '';
          final plot = _tmdbDetails?.overview ?? widget.series.plot;
          final rating = _tmdbDetails?.voteAverage ?? 0.0;

          return DefaultTabController(
            length: seasonKeys.length,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return <Widget>[
                  SliverAppBar(
                    expandedHeight: 250.0.h,
                    floating: false,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      centerTitle: true,
                      title: Text(
                          widget.series.name,
                          style: TextStyle(fontSize: 16.0.sp, shadows: [Shadow(blurRadius: 4.r)])
                      ),
                      background: Image.network(
                        backdropUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Image.network(widget.series.cover ?? '', fit: BoxFit.cover, errorBuilder: (c, e, s) => const Center(child: Icon(Icons.tv))),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(12.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (rating > 0)
                            Row(
                              children: [
                                Icon(Icons.star, color: Colors.amber, size: 20.sp),
                                SizedBox(width: 5.w),
                                Text(
                                  "${rating.toStringAsFixed(1)} / 10 TMDb",
                                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          if (rating > 0) SizedBox(height: 10.h),
                          Text(
                              plot,
                              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14.sp)
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    delegate: _SliverAppBarDelegate(
                      TabBar(
                        isScrollable: true,
                        labelStyle: TextStyle(fontSize: 14.sp),
                        tabs: seasonKeys.map((seasonNum) => Tab(text: 'Sezon $seasonNum')).toList(),
                      ),
                    ),
                    pinned: true,
                  ),
                ];
              },
              body: TabBarView(
                children: seasonKeys.map((seasonNum) {
                  final episodes = seasons[seasonNum]!;
                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: episodes.length,
                    itemBuilder: (context, index) {
                      final episode = episodes[index];
                      return FocusableEpisodeTile(
                        episode: episode,
                        series: widget.series,
                        tmdbDetails: _tmdbDetails,
                        autofocus: index == 0,
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- EKSİK OLAN YARDIMCI SINIF BURADA ---
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

class FocusableEpisodeTile extends StatefulWidget {
  final EpisodeModel episode;
  final SeriesModel series;
  final TmdbDetailsModel? tmdbDetails;
  final bool autofocus;

  const FocusableEpisodeTile({
    super.key,
    required this.episode,
    required this.series,
    required this.tmdbDetails,
    this.autofocus = false,
  });

  @override
  State<FocusableEpisodeTile> createState() => _FocusableEpisodeTileState();
}

class _FocusableEpisodeTileState extends State<FocusableEpisodeTile> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: _isFocused ? Colors.blueGrey.shade800 : Colors.transparent,
      child: ListTile(
        autofocus: widget.autofocus,
        onFocusChange: (hasFocus) {
          setState(() {
            _isFocused = hasFocus;
          });
        },
        leading: CircleAvatar(
          radius: 20.r,
          backgroundColor: _isFocused ? Colors.amber : Colors.amber.shade800,
          child: Text(
            widget.episode.episodeNum.toString(),
            style: TextStyle(
              fontSize: 14.sp,
              color: _isFocused ? Colors.black : Colors.white,
            ),
          ),
        ),
        title: Text(
          widget.episode.title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: _isFocused ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          final auth = Provider.of<AuthProvider>(context, listen: false);
          final credentials = auth.getCredentials();
          final serverUrl = credentials['serverUrl']!;
          final username = credentials['username']!;
          final password = credentials['password']!;

          final fullEpisodeUrl = '$serverUrl/series/$username/$password/${widget.episode.id}.${widget.episode.containerExtension}';

          final contentToPlay = ChannelForDB(
            streamId: int.tryParse(widget.episode.id) ?? 0,
            name: '${widget.series.name} - ${widget.episode.title}',
            streamIcon: widget.tmdbDetails?.fullPosterUrl ?? widget.series.cover,
            mediaType: 'series',
            containerExtension: widget.episode.containerExtension,
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlayerScreen(streamUrl: fullEpisodeUrl, content: contentToPlay),
            ),
          );
        },
      ),
    );
  }
}