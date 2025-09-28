import 'package:cinema_app_flutter/screens/booking_screen.dart';
import 'package:cinema_app_flutter/screens/sigin_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cinema_app_flutter/services/movie_service.dart';
import 'package:cinema_app_flutter/models/movie_detail.dart';
import 'package:cinema_app_flutter/models/video.dart';
import 'package:intl/intl.dart';
import 'package:cinema_app_flutter/main.dart';

class MovieDetailScreen extends ConsumerWidget {
  final int movieId;
  const MovieDetailScreen({super.key, required this.movieId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movieDetailAsync = ref.watch(movieDetailProvider(movieId));

    return movieDetailAsync.when(
      data: (movie) => Scaffold(
        backgroundColor: Colors.black,
        body: CustomScrollView(
          slivers: [
            _MovieTrailer(movieId: movieId),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(movie.title, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    // ✅ 1. HIỂN THỊ THỂ LOẠI
                    _MovieGenres(genreIds: movie.genreIds),
                    const SizedBox(height: 16),
                    _RatingAndDuration(movie: movie),
                    const SizedBox(height: 8),
                    // ✅ 2. HIỂN THỊ LƯỚI THÔNG TIN PHỤ
                    _SupplementalInfo(movie: movie),
                    const SizedBox(height: 12),
                    _ExpandableText(title: 'Nội dung', content: movie.overview),
                    const SizedBox(height: 12),
                    _ProductionInfo(movieId: movieId),
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
              // 1. Đọc trạng thái đăng nhập hiện tại từ provider
              // Dùng ref.read() vì chúng ta ở trong một callback, không cần lắng nghe sự thay đổi
              final user = ref.read(authStateProvider).value;
              // 2. Kiểm tra xem user có null hay không
              if (user != null) {
                // 3. Nếu đã đăng nhập: Chuyển đến màn hình Đặt vé
                Navigator.push(
                  context,
                  MaterialPageRoute(
                  //TRUYỀN DỮ LIỆU PHIM SANG
                    builder: (context) => BookingScreen(
                      movieId: movie.id, 
                      movieTitle: movie.title
                    ),
                  ),
                );
              } else {
                // 4. Nếu chưa đăng nhập: Hiển thị thông báo và chuyển đến màn hình Đăng nhập
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng đăng nhập để tiếp tục!',
                    textAlign: TextAlign.center,
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SignInScreen(),
                  ),
                );
              }
            },
            icon: const Icon(Icons.confirmation_number),
            label: const Text('Đặt vé'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text('Lỗi: $err', style: const TextStyle(color: Colors.white))),
      ),
    );
  }
}

//HIỂN THỊ THỂ LOẠI
class _MovieGenres extends ConsumerWidget {
  final List<int> genreIds;
  const _MovieGenres({required this.genreIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genresAsync = ref.watch(genreProvider);
    return genresAsync.when(
      data: (genreMap) {
        final genreNames = genreIds
            .map((id) => genreMap[id] ?? '')
            .where((name) => name.isNotEmpty)
            .join(', '); // Nối bằng dấu phẩy
        return Text(
          genreNames,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            decoration: TextDecoration.underline, // Gạch chân
            decorationColor: Colors.white70,
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

//HIỂN THỊ LƯỚI THÔNG TIN PHỤ
class _SupplementalInfo extends StatelessWidget {
  final MovieDetail movie;
  const _SupplementalInfo({required this.movie});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 3.5, // Điều chỉnh tỉ lệ cho phù hợp
      children: [
        _infoTile('Khởi chiếu', movie.releaseDate != null ? DateFormat('dd/MM/yyyy').format(movie.releaseDate!) : 'N/A'),
        _infoTile('Ngôn ngữ', movie.originalLanguage),
        _infoTile('Độ tuổi', movie.isAdult ? '18+' : 'Mọi lứa tuổi'),
        _infoTile('Quốc gia', movie.productionCountry),
      ],
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _MovieTrailer extends ConsumerWidget {
  final int movieId;
  const _MovieTrailer({required this.movieId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsync = ref.watch(movieVideosProvider(movieId));
    return SliverAppBar(
      backgroundColor: Colors.black,
      expandedHeight: 220,
      pinned: true,
      flexibleSpace: videosAsync.when(
        data: (videos) {
          //LOGIC TÌM KIẾM
          Video? trailer;
          try {
            // 1. Cố gắng tìm video có type là "Trailer" và site là "YouTube"
            trailer = videos.firstWhere(
              (v) => v.type == 'Trailer' && v.site == 'YouTube',
            );
          } catch (e) {
            // 2. Nếu không tìm thấy, lấy video đầu tiên trong danh sách làm phương án dự phòng
            if (videos.isNotEmpty) {
              trailer = videos.first;
            }
          }

          // 3. Nếu sau tất cả các bước vẫn không có trailer, hiển thị thông báo
          if (trailer == null) {
            return const Center(
                child: Text('Không có trailer',
                    style: TextStyle(color: Colors.white)));
          }

          // 4. Nếu có trailer, hiển thị YoutubePlayer
          return YoutubePlayer(
            controller: YoutubePlayerController(
              initialVideoId: trailer.key,
              flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
            ),
            showVideoProgressIndicator: true,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Icon(Icons.error)),
      ),
    );
  }
}

class _RatingAndDuration extends StatelessWidget {
  final MovieDetail movie;
  const _RatingAndDuration({required this.movie});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Row(
          children: List.generate(5, (index) {
            double rating = movie.voteAverage / 2;
            return Icon(
              index < rating.floor()
                  ? Icons.star
                  : index < rating ? Icons.star_half : Icons.star_border,
              color: Colors.amber,
              size: 20,
            );
          }),
        ),
        const SizedBox(width: 16),
        const Icon(Icons.timer_outlined, color: Colors.white70, size: 18),
        const SizedBox(width: 4),
        Text('${movie.runtime} phút', style: const TextStyle(color: Colors.white70)),
      ],
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
        Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          widget.content,
          maxLines: _isExpanded ? null : 3,
          overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
        ),
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Text(
            _isExpanded ? 'Thu gọn' : 'Xem tiếp',
            style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class _ProductionInfo extends ConsumerWidget {
  final int movieId;
  const _ProductionInfo({required this.movieId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creditsAsync = ref.watch(movieCreditsProvider(movieId));
    return creditsAsync.when(
      data: (credits) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (credits.director != null)
            Text('Đạo diễn: ${credits.director!.name}', style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          Text('Diễn viên: ${credits.cast.take(5).map((c) => c.name).join(', ')}', style: const TextStyle(color: Colors.white)),
        ],
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}