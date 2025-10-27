import 'package:cinema_app_flutter/main.dart';
import 'package:cinema_app_flutter/models/movie_model.dart';
import 'package:cinema_app_flutter/screens/booking_screen.dart';
import 'package:cinema_app_flutter/screens/sigin_screen.dart';
import 'package:cinema_app_flutter/services/movie_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class MovieDetailScreen extends ConsumerWidget {
  final String movieId;
  const MovieDetailScreen({super.key, required this.movieId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movieDetailAsync = ref.watch(movieDetailProvider(movieId));

    return movieDetailAsync.when(
      data: (movie) => Scaffold(
        backgroundColor: Colors.black,
        body: CustomScrollView(
          slivers: [
            _MovieTrailer(trailerUrl: movie.trailerUrl),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(movie.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    // Hiển thị danh sách thể loại
                    Text(
                      movie.genres.join(', '),
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          //decoration: TextDecoration.underline,
                          decorationColor: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    _RatingAndDuration(movie: movie),
                    const SizedBox(height: 24),
                    _SupplementalInfo(movie: movie),
                    const SizedBox(height: 24),
                    _ExpandableText(
                        title: 'Nội dung',
                        content: movie.description), // ✅ Dùng description
                    const SizedBox(height: 24),
                    _ProductionInfo(movie: movie),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () {
              final user = ref.read(authStateProvider).value;
              if (user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => BookingScreen(
                          movieId: movie.id!, movieTitle: movie.title)),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Vui lòng đăng nhập để tiếp tục!')));
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SignInScreen()));
              }
            },
            icon: const Icon(Icons.confirmation_number),
            label: const Text('Đặt vé'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
      loading: () => const Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(
          backgroundColor: Colors.black,
          body: Center(
              child: Text('Lỗi: $err',
                  style: const TextStyle(color: Colors.white)))),
    );
  }
}

class _MovieTrailer extends StatelessWidget {
  final String trailerUrl;
  const _MovieTrailer({required this.trailerUrl});

  @override
  Widget build(BuildContext context) {
    final videoId = YoutubePlayer.convertUrlToId(trailerUrl);

    return SliverAppBar(
      backgroundColor: Colors.black,
      expandedHeight: 220,
      pinned: true,
      flexibleSpace: SafeArea(
        child: (videoId != null)
            ? YoutubePlayer(
                controller: YoutubePlayerController(
                  initialVideoId: videoId,
                  flags: const YoutubePlayerFlags(
                    autoPlay: false,
                    mute: false,
                  ),
                ),
                showVideoProgressIndicator: true,
              )
            : Container(
                color: Colors.black,
                child: const Center(
                  child: Text(
                    'Không có trailer',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
      ),
    );
  }
}

class _RatingAndDuration extends StatelessWidget {
  final Movie movie;
  const _RatingAndDuration({required this.movie});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Row(
          children: List.generate(5, (index) {
            double ratingValue = movie.rating / 2; // ✅ Dùng rating
            return Icon(
              index < ratingValue.floor()
                  ? Icons.star
                  : (index < ratingValue ? Icons.star_half : Icons.star_border),
              color: Colors.amber,
              size: 20,
            );
          }),
        ),
        const SizedBox(width: 16),
        const Icon(Icons.timer_outlined, color: Colors.white70, size: 18),
        const SizedBox(width: 4),
        Text('${movie.duration} phút',
            style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}

class _SupplementalInfo extends StatelessWidget {
  final Movie movie;
  const _SupplementalInfo({required this.movie});

  @override
  Widget build(BuildContext context) {
    return Wrap(
    spacing: 20,
    runSpacing: 10,
    children: [
      _infoTile('Khởi chiếu', DateFormat('dd/MM/yyyy').format(movie.releaseDate)),
      _infoTile('Ngôn ngữ', movie.language),
      _infoTile('Hãng SX', movie.manufacturer),
      _infoTile('Độ tuổi', movie.isNowShowing ? '16+' : 'Mọi lứa tuổi'),
    ],
  );
    // return GridView(
    //   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    //     crossAxisCount: 2,
    //     childAspectRatio: 2, // Tăng tỉ lệ để các mục không quá cao
    //     crossAxisSpacing: 8,
    //     mainAxisSpacing: 8,
    //   ),
    //   shrinkWrap: true,
    //   physics: const NeverScrollableScrollPhysics(),
    //   children: [
    //     _infoTile(
    //         'Khởi chiếu', DateFormat('dd/MM/yyyy').format(movie.releaseDate)),
    //     _infoTile('Ngôn ngữ', movie.language),
    //     _infoTile('Hãng SX', movie.manufacturer),
    //     _infoTile(
    //         'Độ tuổi', movie.isNowShowing ? '16+' : 'Mọi lứa tuổi'), // Ví dụ
    //   ],
    // );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              maxLines: 1, overflow: TextOverflow.ellipsis
              ),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ExpandableText extends StatefulWidget {
  final String title;
  final String content;
  const _ExpandableText({required this.title, required this.content});
  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          widget.content,
          maxLines: _isExpanded ? null : 3,
          overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style:
              const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
              textAlign: TextAlign.justify,
        ),
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Text(
            _isExpanded ? 'Thu gọn' : 'Xem tiếp',
            style: const TextStyle(
                color: Colors.blueAccent, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class _ProductionInfo extends StatelessWidget {
  final Movie movie;
  const _ProductionInfo({required this.movie});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (movie.director.isNotEmpty)
          Text('Đạo diễn: ${movie.director}',
              style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 8),
        if (movie.actors.isNotEmpty)
          Text('Diễn viên: ${movie.actors.join(', ')}',
              style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}
