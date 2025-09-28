import 'dart:ui';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cinema_app_flutter/services/movie_service.dart';
import 'package:cinema_app_flutter/models/movie.dart';
import 'package:intl/intl.dart';
import 'package:cinema_app_flutter/screens/movie_detail_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Controller để điều khiển PageView (carousel)
  late PageController _pageController;
  // Biến để lưu chỉ số của phim đang được chọn ở giữa
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // Khởi tạo PageController với viewportFraction để thấy các poster 2 bên
    _pageController = PageController(viewportFraction: 0.6, initialPage: _currentPage);
    // Lắng nghe sự kiện cuộn để cập nhật lại UI
    _pageController.addListener(() {
      int next = _pageController.page!.round();
      if (_currentPage != next) {
        setState(() {
          _currentPage = next;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe provider phim
    final moviesAsync = ref.watch(nowPlayingMoviesProvider);
    // final size = MediaQuery.of(context).size;
    // print('Screen Size: width=${size.width}, height=${size.height}');

    return Scaffold(
      // Dùng .when để xử lý các trạng thái của provider
      body: moviesAsync.when(
        data: (movies) {
          // Nếu không có phim nào, hiển thị thông báo
          if (movies.isEmpty) {
            return const Center(child: Text('Không có phim nào đang chiếu.'));
          }
          // Lấy phim nổi bật hiện tại
          final featuredMovie = movies[_currentPage % movies.length];

          // DÙNG STACK ĐỂ XẾP CHỒNG CÁC LỚP UI
          return Stack(
            fit: StackFit.expand,
            children: [
              // LỚP 1: Nền mờ
              _buildBackground(featuredMovie),
              // LỚP 2: Nội dung chính
              _buildContent(movies),
              // LỚP 3: Thanh điều hướng dưới cùng
              _buildBottomNavBar(),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi tải phim: $err')),
      ),
    );
  }

  // Widget xây dựng lớp nền
  Widget _buildBackground(Movie movie) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Ảnh nền
        Image.network(
          movie.backdropPath, // Dùng ảnh backdrop cho nền rộng hơn
          fit: BoxFit.cover,
        ),
        // Hiệu ứng mờ
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Container(color: Colors.transparent),
        ),
        // Lớp phủ tối
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black.withAlpha(153), Colors.black.withAlpha(230)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  // Widget xây dựng lớp nội dung
  Widget _buildContent(List<Movie> movies) {
    final featuredMovie = movies[_currentPage % movies.length];

    return SafeArea(
      child: Column(
        children: [
          SizedBox(height: 24.h),
          Text(
            featuredMovie.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(blurRadius: 10.0, color: Colors.black)],
            ),
          ),
          SizedBox(height: 12.h),
          // Widget mới cho Điểm đánh giá và Ngày phát hành
          _RatingAndDate(movie: featuredMovie),
          const Spacer(),
          // Carousel poster phim
          SizedBox(
            height: 350.h,
            child: PageView.builder(
              controller: _pageController,
              itemCount: movies.length * 100, // Tăng số lượng để tạo hiệu ứng vô hạn
              itemBuilder: (context, index) {
                return AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    double value = 1.0;
                    if (_pageController.position.haveDimensions) {
                      value = (_pageController.page! - index).abs();
                      value = (1 - (value * 0.4)).clamp(0.0, 1.0);
                    }
                    return Transform.scale(
                      scale: Curves.easeOut.transform(value),
                      child: child,
                    );
                  },
                  // Gọi widget card mới
                  child: _MoviePosterCard(movie: movies[index % movies.length]),
                );
              },
            ),
          ),
          const Spacer(),
          // Widget mới cho Thể loại
          _MovieGenres(genreIds: featuredMovie.genreIds),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 60.w, vertical: 18.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
              elevation: 8.0,
              shadowColor: Colors.redAccent.withAlpha(128),
            ),
            child: Text(
              'Đặt Vé',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }


  // Widget xây dựng thanh điều hướng dưới cùng
  Widget _buildBottomNavBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30.r),
          topRight: Radius.circular(30.r),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            height: 70.h,
            color: Colors.white.withAlpha(26),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navBarIcon(Icons.support_agent_outlined),
                _navBarIcon(Icons.local_offer_outlined),
                // Icon Home nổi bật
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.redAccent,
                  ),
                  child: Icon(Icons.home, color: Colors.white, size: 28.sp),
                ),
                _navBarIcon(Icons.theaters_outlined),
                _navBarIcon(Icons.person_outline),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget nhỏ cho các icon trên thanh điều hướng
  Widget _navBarIcon(IconData icon) {
    return IconButton(
      onPressed: () {},
      icon: Icon(icon, color: Colors.white70, size: 24.sp),
    );
  }
}

//WIDGET HIỂN THỊ THỂ LOẠI
class _MovieGenres extends ConsumerWidget {
  final List<int> genreIds;
  const _MovieGenres({required this.genreIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genres = ref.watch(genreProvider);
    return genres.when(
      data: (genreMap) {
        final genreNames = genreIds
            .map((id) => genreMap[id] ?? '')
            .where((name) => name.isNotEmpty)
            .join(' · ');
        return Text(
          genreNames,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 12.sp),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

//CARD POSTER VỚI NHÃN DÁN
class _MoviePosterCard extends StatelessWidget {
  const _MoviePosterCard({required this.movie});
  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 12.0),
      child: GestureDetector(
        // ✅ CẬP NHẬT HÀM ONTAP
        onTap: () {
          // In ra log để kiểm tra
          log('Tapped on movie ID: ${movie.id}');

          // Điều hướng đến màn hình chi tiết, truyền ID của phim
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MovieDetailScreen(movieId: movie.id),
            ),
          );
        },
        child: Stack(
          children: [
        // Poster
        ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: Image.network(movie.posterPath, fit: BoxFit.contain),
        ),
        // Nhãn dán
        Positioned(
          top: 0,
          right: 1,
          child: _SpecialLabel(movie: movie),
        ),
      ],
        ),
      ),
    );
  }
}

//LOGIC HIỂN THỊ NHÃN DÁN "HOT" / "MỚI"
class _SpecialLabel extends StatelessWidget {
  const _SpecialLabel({required this.movie});
  final Movie movie;

  @override
  Widget build(BuildContext context) {
    final isHot = movie.voteAverage > 8.0;
    final isNew = movie.releaseDate != null &&
        DateTime.now().difference(movie.releaseDate!).inDays <= 30;

    String? label;
    Color? color;
    if (isHot) {
      label = 'Hot🔥';
      color = Colors.redAccent;
    } else if (isNew) {
      label = 'Mới Ra Mắt';
      color = Colors.blueAccent;
    }

    if (label == null) {
      return const SizedBox.shrink(); // Không hiển thị gì cả
    }

    return Chip(
      label: Text(label),
      backgroundColor: color,
      labelStyle: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold),
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 2.h),
    );
  }
}

//HIỂN THỊ ĐIỂM ĐÁNH GIÁ VÀ NGÀY PHÁT HÀNH
class _RatingAndDate extends StatelessWidget {
  const _RatingAndDate({required this.movie});
  final Movie movie;

  @override
  Widget build(BuildContext context) {
    final releaseDate = movie.releaseDate != null
        ? DateFormat('dd/MM/yyyy').format(movie.releaseDate!)
        : 'N/A';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Vòng tròn tiến trình cho điểm
        SizedBox(
          width: 40.w,
          height: 40.h,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: movie.voteAverage / 10.0,
                strokeWidth: 4,
                backgroundColor: Colors.grey.shade700,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              ),
              Center(
                child: Text(
                  movie.voteAverage.toStringAsFixed(1),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 16.w),
        // Ngày phát hành
        Text(
          releaseDate,
          style: TextStyle(color: Colors.white70, fontSize: 14.sp),
        ),
      ],
    );
  }
}