import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:carousel_slider/carousel_slider.dart'; 
import '../models/cinema_model.dart';
import '../services/movie_service.dart'; 
import 'cinema_showtimes_screen.dart'; 

class CinemaListScreen extends ConsumerWidget {
  const CinemaListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cinemasAsync = ref.watch(cinemasStreamProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100, 
      appBar: AppBar(
        title: const Text('Danh sách Rạp phim'),
        elevation: 1,
      ),
      body: cinemasAsync.when(
        data: (cinemas) {
          if (cinemas.isEmpty) {
            return const Center(child: Text('Chưa có rạp nào.'));
          }
          return ListView.builder(        
            padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 20.h, bottom: 90.h),
            itemCount: cinemas.length,
            itemBuilder: (context, index) {
              return _CinemaCard(cinema: cinemas[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi tải danh sách rạp: $err')),
      ),
    );
  }
}

class _CinemaCard extends StatelessWidget {
  final Cinema cinema;
  const _CinemaCard({required this.cinema});

  Future<void> _launchMaps(BuildContext context, double lat, double lon) async {
    final Uri googleMapsUrl = Uri.parse(
  'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(cinema.address)}',
);
    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Không thể mở Google Maps.')),
         );
      }
    } catch(e) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Lỗi mở bản đồ: $e')),
       );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 20.h),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
             padding: EdgeInsets.all(16.r),
             child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                    Text(
                       cinema.name,
                       style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                       children: [
                          Image.network(cinema.logoUrl, height: 24.h, errorBuilder: (c,e,s)=>const SizedBox()),
                          SizedBox(width: 8.w),
                          Icon(Icons.location_on_outlined, size: 16.sp, color: Colors.grey.shade600),
                          SizedBox(width: 4.w),
                          Expanded(
                             child: Text(
                                cinema.address,
                                style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade700),
                                overflow: TextOverflow.ellipsis,
                             ),
                          ),
                       ],
                    ),
                     SizedBox(height: 8.h),
                     Row(
                        children: [
                           Icon(Icons.access_time_outlined, size: 16.sp, color: Colors.grey.shade600),
                           SizedBox(width: 4.w),
                           Text(
                              'Giờ mở cửa: ${cinema.openingHours}',
                              style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade700),
                           ),
                           const Spacer(), 
                           Icon(Icons.phone_outlined, size: 16.sp, color: Colors.grey.shade600),
                            SizedBox(width: 4.w),
                           Text(
                              cinema.phone,
                              style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade700),
                           ),
                        ],
                     ),
                 ],
             )
          ),
          const Divider(height: 1),

          if (cinema.amenities.isNotEmpty)
             Padding(
               padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
               child: Row(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Icon(Icons.widgets_outlined, size: 18.sp, color: Colors.blueAccent),
                   SizedBox(width: 8.w),
                   Expanded(
                     child: Wrap(
                       spacing: 8.w,
                       runSpacing: 4.h,
                       children: cinema.amenities.map((amenity) => Chip(
                         label: Text(amenity, style: TextStyle(fontSize: 11.sp)),
                         padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                         backgroundColor: Colors.blueAccent.withOpacity(0.1),
                         side: BorderSide.none,
                         visualDensity: VisualDensity.compact,
                       )).toList(),
                     ),
                   ),
                 ],
               ),
             ),

           if (cinema.imageUrls.isNotEmpty)
              Padding(
                 padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                 child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Row(
                          children: [
                             Icon(Icons.photo_library_outlined, size: 18.sp, color: Colors.green),
                             SizedBox(width: 8.w),
                             Text('Hình ảnh rạp:', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500)),
                          ],
                       ),
                       SizedBox(height: 8.h),
                       CarouselSlider(
                         options: CarouselOptions(
                           height: 120.h,
                           viewportFraction: 0.8, // Ảnh lớn hơn một chút
                           enableInfiniteScroll: false, // Không lặp lại
                           autoPlay: false, // Tắt tự động chạy
                            enlargeCenterPage: true, // Ảnh ở giữa lớn hơn
                            padEnds: false, // Ảnh đầu/cuối sát lề
                         ),
                         items: cinema.imageUrls.map((url) {
                           return Builder(
                             builder: (BuildContext context) {
                               return Container(
                                 width: MediaQuery.of(context).size.width,
                                 margin: EdgeInsets.symmetric(horizontal: 5.w),
                                 child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10.r),
                                    child: Image.network(
                                       url,
                                       fit: BoxFit.cover,
                                       loadingBuilder: (context, child, loadingProgress) {
                                         if (loadingProgress == null) return child;
                                         return const Center(child: CircularProgressIndicator());
                                       },
                                       errorBuilder: (context, error, stackTrace) =>
                                          Container(color: Colors.grey.shade300, child: const Icon(Icons.error_outline)),
                                    ),
                                 ),
                               );
                             },
                           );
                         }).toList(),
                       ),
                    ],
                 ),
              ),

          Container(
             color: Colors.grey.shade50, 
             padding: EdgeInsets.symmetric(vertical: 8.h),
             child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
               children: [
                 TextButton.icon(
                   icon: Icon(Icons.directions_outlined, color: Colors.blue),
                   label: Text('Chỉ đường', style: TextStyle(color: Colors.blue)),
                   onPressed: () => _launchMaps(context, cinema.location.latitude, cinema.location.longitude),
                 ),
                 TextButton.icon(
                   icon: Icon(Icons.theaters_outlined, color: Colors.redAccent),
                   label: Text('Suất chiếu', style: TextStyle(color: Colors.redAccent)),
                   onPressed: () {
                     Navigator.push(
                       context,
                       MaterialPageRoute(
                         builder: (context) => CinemaShowtimesScreen(
                           cinemaId: cinema.id!,
                           cinemaName: cinema.name,
                         ),
                       ),
                     );
                   },
                 ),
               ],
             ),
          ),
        ],
      ),
    );
  }
}