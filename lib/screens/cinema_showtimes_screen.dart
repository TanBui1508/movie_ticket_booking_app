import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import '../models/movie_model.dart';
import '../models/showtime_model.dart';
import '../services/movie_service.dart';
import 'movie_detail_screen.dart';
import 'seat_selection_screen.dart';

// Provider để lấy danh sách phim (chỉ lấy 1 lần để lấy tên phim)
final allMoviesFutureProvider = FutureProvider<List<Movie>>((ref) {
  // Dùng .getNowShowingMoviesStream().first để lấy data 1 lần
  // Hoặc tạo hàm getMovies() trong service nếu cần lấy tất cả phim
  return ref.watch(movieServiceProvider).getNowShowingMoviesStream().first;
});

class CinemaShowtimesScreen extends ConsumerStatefulWidget {
  final String cinemaId;
  final String cinemaName;

  const CinemaShowtimesScreen({
    super.key,
    required this.cinemaId,
    required this.cinemaName,
  });

  @override
  ConsumerState<CinemaShowtimesScreen> createState() =>
      _CinemaShowtimesScreenState();
}

class _CinemaShowtimesScreenState extends ConsumerState<CinemaShowtimesScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final allShowtimesAsync = ref.watch(allShowtimesProvider);
    final allMoviesAsync =
        ref.watch(allMoviesFutureProvider); 

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.cinemaName),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: _buildDateSelector(),
          ),
          const Divider(color: Colors.grey, height: 1),
          Expanded(
            child: allShowtimesAsync.when(
              data: (allShowtimes) {
                final filteredShowtimes = allShowtimes.where((s) {
                  final localStartTime = s.startTime.toLocal();
                  return s.cinemaId == widget.cinemaId &&
                      DateUtils.isSameDay(
                          _selectedDate, localStartTime); 
                }).toList();

                if (filteredShowtimes.isEmpty) {
                  return const Center(
                    child: Text('Không có suất chiếu cho ngày này tại rạp này.',
                        style: TextStyle(color: Colors.white70)),
                  );
                }

                final showtimesByMovie =
                    groupBy(filteredShowtimes, (Showtime s) => s.movieId);

                return allMoviesAsync.when(
                  data: (movies) {
                    final movieMap = {
                      for (var m in movies) m.id: m
                    }; // Map ID -> Movie

                    return ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: showtimesByMovie.keys.length,
                      itemBuilder: (context, index) {
                        final movieId = showtimesByMovie.keys.elementAt(index);
                        final movie = movieMap[movieId];
                        final showtimesForMovie =
                            showtimesByMovie[movieId] ?? [];

                        if (movie == null) {
                          return const SizedBox
                              .shrink(); // Bỏ qua nếu không tìm thấy phim
                        }
                        return _MovieShowtimeItem(
                          movie: movie,
                          showtimes: showtimesForMovie,
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(
                      child: Text('Lỗi tải danh sách phim: $e',
                          style: const TextStyle(color: Colors.red))),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(
                  child: Text('Lỗi tải suất chiếu: $e',
                      style: const TextStyle(color: Colors.red))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    final today = DateTime.now();
    final days = List.generate(7, (index) => today.add(Duration(days: index)));

    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: days.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final date = days[index];
          final isSelected = _selectedDate.year == date.year &&
              _selectedDate.month == date.month &&
              _selectedDate.day == date.day;

          return ChoiceChip(
            label: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('E', 'vi').format(date),
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  DateFormat('dd/MM').format(date),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                setState(() => _selectedDate = date);
              }
            },
            backgroundColor: Colors.grey.shade800,
            selectedColor: Colors.redAccent,
            labelStyle: const TextStyle(color: Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey.shade700),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          );
        },
      ),
    );
  }
}

class _MovieShowtimeItem extends StatelessWidget {
  final Movie movie;
  final List<Showtime> showtimes;

  const _MovieShowtimeItem({required this.movie, required this.showtimes});

  @override
  Widget build(BuildContext context) {
    showtimes.sort((a, b) => a.startTime.compareTo(b.startTime));

    return Card(
      color: Colors.grey.shade900,
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            MovieDetailScreen(movieId: movie.id!)));
              },
              child: Text(
                movie.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${movie.duration} phút | ${movie.genres.join(', ')}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10.0,
              runSpacing: 8.0,
              children: showtimes
                  .map((showtime) => ActionChip(
                        label: Text(
                            DateFormat('HH:mm').format(showtime.startTime)),
                        backgroundColor: Colors.grey.shade800,
                        labelStyle: const TextStyle(color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SeatSelectionScreen(
                                movieTitle: movie.title,
                                showtime: showtime,
                              ),
                            ),
                          );
                        },
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey.shade700)),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
