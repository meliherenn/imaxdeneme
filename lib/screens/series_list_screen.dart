import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:imaxip/models/series_model.dart';
import 'package:imaxip/providers/auth_provider.dart';
import 'package:imaxip/screens/series_info_screen.dart';
import 'package:provider/provider.dart';
import 'package:imaxip/services/api_service.dart';
import '../models/channel_model_for_db.dart';
import '../services/database_helper.dart';

class SeriesListScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const SeriesListScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<SeriesListScreen> createState() => _SeriesListScreenState();
}

class _SeriesListScreenState extends State<SeriesListScreen> {
  late Future<List<SeriesModel>> _seriesFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final credentials = auth.getCredentials();

    _seriesFuture = _apiService.getSeriesByCategoryId(
      serverUrl: credentials['serverUrl']!,
      username: credentials['username']!,
      password: credentials['password']!,
      categoryId: widget.categoryId,
    ).then((list) => list.map((item) => SeriesModel.fromJson(item)).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
      ),
      body: FutureBuilder<List<SeriesModel>>(
        future: _seriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.amber));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Bu kategoride dizi bulunamadı.'));
          }

          final seriesList = snapshot.data!;
          return GridView.builder(
            padding: EdgeInsets.all(10.w),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2 / 3.5,
              crossAxisSpacing: 10.w,
              mainAxisSpacing: 10.h,
            ),
            itemCount: seriesList.length,
            itemBuilder: (context, index) {
              final series = seriesList[index];
              return FavoriteSeriesTile(
                series: series,
                autofocus: index == 0,
              );
            },
          );
        },
      ),
    );
  }
}

class FavoriteSeriesTile extends StatefulWidget {
  final SeriesModel series;
  final bool autofocus;

  const FavoriteSeriesTile({
    super.key,
    required this.series,
    this.autofocus = false,
  });

  @override
  State<FavoriteSeriesTile> createState() => _FavoriteSeriesTileState();
}

class _FavoriteSeriesTileState extends State<FavoriteSeriesTile> {
  bool _isFavorite = false;
  bool _isFocused = false;
  late DatabaseHelper _dbHelper;

  @override
  void initState() {
    super.initState();
    _dbHelper = DatabaseHelper();
    _checkIfFavorite();
  }

  void _checkIfFavorite() async {
    final isFav = await _dbHelper.isFavorite(widget.series.seriesId);
    if (mounted) {
      setState(() {
        _isFavorite = isFav;
      });
    }
  }

  void _toggleFavorite() {
    final seriesToSave = ChannelForDB(
      streamId: widget.series.seriesId,
      name: widget.series.name,
      streamIcon: widget.series.cover,
      mediaType: 'series',
      categoryId: widget.series.categoryId,
    );

    if (_isFavorite) {
      _dbHelper.removeFavorite(widget.series.seriesId);
    } else {
      _dbHelper.addFavorite(seriesToSave);
    }
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isFocused ? 1.1 : 1.0,
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
                Navigator.push(context, MaterialPageRoute(builder: (context) => SeriesInfoScreen(series: widget.series)));
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
                child: widget.series.cover != null && widget.series.cover!.isNotEmpty
                    ? Image.network(
                  widget.series.cover!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.tv, color: Colors.white70)),
                )
                    : const Center(child: Icon(Icons.tv, color: Colors.white70)),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  widget.series.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.sp),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
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