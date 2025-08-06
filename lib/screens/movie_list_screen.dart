import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:imaxip/models/movie_model.dart';
import 'package:imaxip/providers/auth_provider.dart';
import 'package:imaxip/screens/movie_info_screen.dart';
import 'package:provider/provider.dart';
import 'package:imaxip/services/api_service.dart';
import '../models/channel_model_for_db.dart';
import '../services/database_helper.dart';

class MovieListScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const MovieListScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  late Future<List<MovieModel>> _moviesFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final credentials = auth.getCredentials();

    _moviesFuture = _apiService.getVodStreams(
      serverUrl: credentials['serverUrl']!,
      username: credentials['username']!,
      password: credentials['password']!,
      categoryId: widget.categoryId,
    ).then((list) => list.map((item) => MovieModel.fromJson(item)).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
      ),
      body: FutureBuilder<List<MovieModel>>(
        future: _moviesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.amber));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Bu kategoride film bulunamadı.'));
          }

          final movies = snapshot.data!;
          return GridView.builder(
            padding: EdgeInsets.all(10.w),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2 / 3.5,
              crossAxisSpacing: 10.w,
              mainAxisSpacing: 10.h,
            ),
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              return FavoriteMovieTile(
                movie: movie,
                autofocus: index == 0, // İlk elemana otomatik odaklan
              );
            },
          );
        },
      ),
    );
  }
}

class FavoriteMovieTile extends StatefulWidget {
  final MovieModel movie;
  final bool autofocus;

  const FavoriteMovieTile({
    super.key,
    required this.movie,
    this.autofocus = false,
  });

  @override
  State<FavoriteMovieTile> createState() => _FavoriteMovieTileState();
}

class _FavoriteMovieTileState extends State<FavoriteMovieTile> {
  bool _isFavorite = false;
  bool _isFocused = false; // Odaklanma durumu için state
  late DatabaseHelper _dbHelper;

  @override
  void initState() {
    super.initState();
    _dbHelper = DatabaseHelper();
    _checkIfFavorite();
  }

  void _checkIfFavorite() async {
    final isFav = await _dbHelper.isFavorite(widget.movie.streamId);
    if (mounted) {
      setState(() {
        _isFavorite = isFav;
      });
    }
  }

  void _toggleFavorite() {
    final movieToSave = ChannelForDB(
      streamId: widget.movie.streamId,
      name: widget.movie.name,
      streamIcon: widget.movie.streamIcon,
      mediaType: 'movie',
      categoryId: widget.movie.categoryId,
      containerExtension: widget.movie.containerExtension,
    );

    if (_isFavorite) {
      _dbHelper.removeFavorite(widget.movie.streamId);
    } else {
      _dbHelper.addFavorite(movieToSave);
    }
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isFocused ? 1.1 : 1.0, // Odaklandığında büyüt
      duration: const Duration(milliseconds: 200),
      child: Column(
        children: [
          Expanded(
            child: InkWell(
              autofocus: widget.autofocus,
              onFocusChange: (hasFocus) {
                setState(() {
                  _isFocused = hasFocus;
                });
              },
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MovieInfoScreen(
                      movie: widget.movie,
                    ),
                  ),
                );
              },
              child: Card(
                elevation: _isFocused ? 12 : 4,
                color: Colors.grey.shade800,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  side: BorderSide(
                    color: _isFocused ? Colors.amber : Colors.transparent,
                    width: 2.0,
                  ),
                ),
                child: widget.movie.streamIcon != null && widget.movie.streamIcon!.isNotEmpty
                    ? Image.network(
                  widget.movie.streamIcon!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.movie, color: Colors.white70)),
                )
                    : const Center(child: Icon(Icons.movie, color: Colors.white70)),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  widget.movie.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.sp),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                icon: Icon(
                  _isFavorite ? Icons.star : Icons.star_border,
                  color: _isFavorite ? Colors.amber : Colors.grey,
                  size: 20.sp,
                ),
                onPressed: _toggleFavorite,
              ),
            ],
          ),
        ],
      ),
    );
  }
}