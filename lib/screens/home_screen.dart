import 'dart:ui';
import 'package:carousel_slider/carousel_slider.dart'; 
import 'package:cinema_app_flutter/screens/booking_screen.dart';
import 'package:cinema_app_flutter/screens/sigin_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cinema_app_flutter/services/movie_service.dart';
import 'package:cinema_app_flutter/models/movie_model.dart'; 
import 'package:intl/intl.dart';
import 'package:cinema_app_flutter/screens/movie_detail_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cinema_app_flutter/main.dart';
import 'package:cinema_app_flutter/screens/profile_screen.dart';


class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentPage = 0;
  int _selectedIndex = 2; 

  // Danh sách các widget con, tương ứng với các mục điều hướng
  static const List<Widget> _pages = <Widget>[
    Scaffold(body: Center(child: Text('Hỗ trợ'))),       // Index 0
    Scaffold(body: Center(child: Text('Ưu đãi'))),        // Index 1
    HomeScreen(),                                    // Index 2 (Nội dung chính của trang Home)
    Scaffold(body: Center(child: Text('Rạp phim'))),     // Index 3
    UserProfileScreen(),                               // Index 4
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final moviesAsync = ref.watch(nowShowingMoviesProvider); 
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      body: moviesAsync.when(
        data: (movies) {
          if (movies.isEmpty) {
            return const Center(child: Text('Không có phim nào đang chiếu.'));
          }
          // Đảm bảo _currentPage không vượt quá giới hạn
          if (_currentPage >= movies.length) {
            _currentPage = 0;
          }
          final featuredMovie = movies[_currentPage];

          return Stack(
            fit: StackFit.expand,
            children: [
              _buildBackground(featuredMovie),
              _buildContent(movies, authState),
              //_buildBottomNavBar(),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi tải phim: $err')),
      ),
    );
  }

  Widget _buildBackground(Movie movie) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(movie.bannerUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => const SizedBox()),
        BackdropFilter(filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), child: Container(color: Colors.transparent)),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black.withValues(alpha: 0.6), Colors.black.withValues(alpha: 0.9)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(List<Movie> movies, AsyncValue<User?> authState) {
    final featuredMovie = movies[_currentPage];

    return SafeArea(
      child: Column(
        children: [
          SizedBox(height: 24.h),
          Text(featuredMovie.title, textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 28.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 12.h),
          _RatingAndDate(movie: featuredMovie),
          const Spacer(),
          CarouselSlider.builder(
            itemCount: movies.length,
            itemBuilder: (context, index, realIndex) {
              return _MoviePosterCard(movie: movies[index]);
            },
            options: CarouselOptions(
              height: 350.h,
              enlargeCenterPage: true,
              viewportFraction: 0.6,
              enlargeFactor: 0.25,
              initialPage: _currentPage,
              onPageChanged: (index, reason) {
                setState(() => _currentPage = index);
              },
            ),
          ),
          const Spacer(),
          _MovieGenres(genres: featuredMovie.genres), 
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () {
              final user = authState.value;
              if (user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingScreen(movieId: featuredMovie.id!, movieTitle: featuredMovie.title),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập để tiếp tục!')));
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SignInScreen()));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 60.w, vertical: 18.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
            ),
            child: Text('Đặt Vé', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  // Widget _buildBottomNavBar() {
  //   return Align(
  //     alignment: Alignment.bottomCenter,
  //     child: ClipRRect(
  //       borderRadius: BorderRadius.only(
  //         topLeft: Radius.circular(30.r),
  //         topRight: Radius.circular(30.r),
  //       ),
  //       child: BackdropFilter(
  //         filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
  //         child: Container(
  //           height: 70.h,
  //           color: Colors.white.withAlpha(26),
  //           child: Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceAround,
  //             children: [
  //               _navBarIcon(Icons.support_agent_outlined),
  //               _navBarIcon(Icons.local_offer_outlined),
  //               // Icon Home
  //               Container(
  //                 padding: EdgeInsets.all(12.r),
  //                 decoration: const BoxDecoration(
  //                   shape: BoxShape.circle,
  //                   color: Colors.redAccent,
  //                 ),
  //                 child: Icon(Icons.home, color: Colors.white, size: 28.sp),
  //               ),
  //               _navBarIcon(Icons.theaters_outlined),
  //               _navBarIcon(Icons.person_outline),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // Widget _navBarIcon(IconData icon) {
  //   return IconButton(
  //     onPressed: () {},
  //     icon: Icon(icon, color: Colors.white70, size: 24.sp),
  //   );
  // }
}

class _MovieGenres extends StatelessWidget {
  final List<String> genres;
  const _MovieGenres({required this.genres});

  @override
  Widget build(BuildContext context) {
    return Text(
      genres.join(' - '),
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.white70, fontSize: 14.sp),     
    );
  }
}

class _MoviePosterCard extends StatelessWidget {
  final Movie movie;
  const _MoviePosterCard({required this.movie});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: GestureDetector(
        onTap: () {
          if (movie.id != null) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => MovieDetailScreen(movieId: movie.id!)));
          }
        },
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: Image.network(movie.posterUrl, fit: BoxFit.contain, errorBuilder: (c, e, s) => const Icon(Icons.movie)),
            ),
            Positioned(
              top: 12.h,
              left: 12.w,
              child: _SpecialLabel(movie: movie),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecialLabel extends StatelessWidget {
  final Movie movie;
  const _SpecialLabel({required this.movie});

  @override
  Widget build(BuildContext context) {
    // ✅ SỬA: Dùng rating
    final isHot = movie.rating > 8.0; 
    final isNew = movie.releaseDate.isAfter(DateTime.now().subtract(const Duration(days: 30)));

    String? label;
    if (isHot) {
      label = 'Hot 🔥';
    } else if (isNew) {
      label = 'Mới Ra Mắt';
    }
    
    if (label == null) return const SizedBox.shrink();

    return Chip(
      label: Text(label),
      backgroundColor: isHot ? Colors.redAccent : Colors.blueAccent,
      labelStyle: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold),
    );
  }
}

class _RatingAndDate extends StatelessWidget {
  final Movie movie;
  const _RatingAndDate({required this.movie});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 40.w,
          height: 40.h,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ✅ SỬA: Dùng rating
              CircularProgressIndicator(value: movie.rating / 10.0, strokeWidth: 4, backgroundColor: Colors.grey.shade700, valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber)),
              Center(child: Text(movie.rating.toStringAsFixed(1), style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold))),
            ],
          ),
        ),
        SizedBox(width: 16.w),
        Text(DateFormat('dd/MM/yyyy').format(movie.releaseDate), style: TextStyle(color: Colors.white70, fontSize: 14.sp)),
      ],
    );
  }
}