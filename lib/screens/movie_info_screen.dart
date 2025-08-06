import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:imaxip/models/movie_model.dart';
import 'package:imaxip/providers/auth_provider.dart';
import 'package:imaxip/screens/player_screen.dart';
import 'package:imaxip/services/tmdb_service.dart';
import 'package:imaxip/models/tmdb_details_model.dart';
import 'package:provider/provider.dart';
import '../models/channel_model_for_db.dart';

class MovieInfoScreen extends StatefulWidget {
  final MovieModel movie;

  const MovieInfoScreen({super.key, required this.movie});

  @override
  State<MovieInfoScreen> createState() => _MovieInfoScreenState();
}

class _MovieInfoScreenState extends State<MovieInfoScreen> {
  final TmdbService _tmdbService = TmdbService();
  TmdbDetailsModel? _tmdbDetails;

  @override
  void initState() {
    super.initState();
    _loadTmdbData();
  }

  Future<void> _loadTmdbData() async {
    final details = await _tmdbService.fetchDetails(
      name: widget.movie.name,
      mediaType: 'movie',
    );
    if (mounted) {
      setState(() {
        _tmdbDetails = details;
      });
    }
  }

  void _playMovie() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final credentials = auth.getCredentials();
    final serverUrl = credentials['serverUrl']!;
    final username = credentials['username']!;
    final password = credentials['password']!;

    final fullMovieUrl = '$serverUrl/movie/$username/$password/${widget.movie.streamId}.${widget.movie.containerExtension}';

    final contentToPlay = ChannelForDB(
      streamId: widget.movie.streamId,
      name: widget.movie.name,
      streamIcon: _tmdbDetails?.fullPosterUrl ?? widget.movie.streamIcon,
      mediaType: 'movie',
      containerExtension: widget.movie.containerExtension,
    );

    Navigator.push(context, MaterialPageRoute(
      builder: (context) => PlayerScreen(streamUrl: fullMovieUrl, content: contentToPlay),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // TMDB verisi olmasa bile Xtream'den gelen verileri kullanalım
    final title = _tmdbDetails?.title ?? widget.movie.name;
    final posterUrl = _tmdbDetails?.fullPosterUrl ?? widget.movie.streamIcon ?? '';
    final backdropUrl = _tmdbDetails?.fullBackdropUrl ?? widget.movie.streamIcon ?? '';
    final plot = _tmdbDetails?.overview ?? 'Açıklama bulunamadı.';
    final rating = _tmdbDetails?.voteAverage ?? 0.0;

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: 250.0.h,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                  title,
                  style: TextStyle(fontSize: 16.0.sp, shadows: const [Shadow(blurRadius: 4.0)])
              ),
              background: Image.network(
                backdropUrl.isNotEmpty ? backdropUrl : posterUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.movie)),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Oynat butonu her zaman görünsün
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                        onPressed: _playMovie,
                        icon: const Icon(Icons.play_arrow),
                        label: Text("OYNAT", style: TextStyle(fontSize: 16.sp)),
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // Sadece TMDB verisi varsa puanı göster
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

                    // Açıklamayı göster
                    Text(
                        plot,
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14.sp)
                    ),

                    // TMDB verisi yüklenirken küçük bir gösterge
                    if (_tmdbDetails == null)
                      const Padding(
                        padding: EdgeInsets.only(top: 20.0),
                        child: Center(child: Text("Ek bilgiler yükleniyor...")),
                      ),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}