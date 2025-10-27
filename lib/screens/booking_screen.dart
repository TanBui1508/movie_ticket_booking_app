import 'package:cinema_app_flutter/models/cinema_model.dart';
import 'package:cinema_app_flutter/models/showtime_model.dart';
import 'package:cinema_app_flutter/screens/seat_selection_screen.dart';
import 'package:cinema_app_flutter/services/movie_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final String movieId;
  final String movieTitle;

  const BookingScreen({
    super.key,
    required this.movieId,
    required this.movieTitle,
  });

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedCinemaId;
  Showtime? _selectedShowtime;

  @override
  Widget build(BuildContext context) {
    final allShowtimesAsync = ref.watch(allShowtimesProvider);
    final allCinemasAsync = ref.watch(cinemasStreamProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.movieTitle),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chọn ngày',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildDateSelector(),
            const SizedBox(height: 24),
            const Text('Chọn rạp và suất chiếu',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: allShowtimesAsync.when(
                data: (allShowtimes) {
                  final now = DateTime.now(); 
                  final filteredShowtimes = allShowtimes.where((s) {
                    final localStartTime =
                        s.startTime.toLocal(); 

                    bool isCorrectMovie =
                        s.movieId == widget.movieId; 

                    bool isCorrectDate =
                        DateUtils.isSameDay(_selectedDate, localStartTime);

                    bool isFutureShowtime = true;
                    if (DateUtils.isSameDay(_selectedDate, now)) {
                      isFutureShowtime = localStartTime
                          .isAfter(now.subtract(const Duration(minutes: 10)));
                    }

                    return isCorrectMovie &&
                        isCorrectDate &&
                        isFutureShowtime; 
                  }).toList();

                  if (filteredShowtimes.isEmpty) {
                    return const Center(
                      child: Text(
                          'Không có suất chiếu cho ngày này tại rạp này.',
                          style: TextStyle(color: Colors.white70)),
                    );
                  }

                  // Lồng .when cho rạp
                  return allCinemasAsync.when(
                    data: (allCinemas) {
                        // ✅ SỬA Ở ĐÂY: GỌI WIDGET BUILD LIST
                        return _buildCinemaAndShowtimeList(filteredShowtimes, allCinemas);
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Text('Lỗi tải rạp: $e', style: const TextStyle(color: Colors.red)),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Text('Lỗi tải suất chiếu: $e',
                    style: const TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        // ✅ THÊM PADDING ĐỂ TRÁNH THANH CÔNG CỤ HỆ THỐNG
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewPadding.bottom > 0 
                    ? MediaQuery.of(context).viewPadding.bottom 
                    : 16.0, // Thêm padding mặc định nếu không có thanh hệ thống
            left: 16.0,
            right: 16.0,
            top: 16.0
        ),
        child: ElevatedButton(
          onPressed: (_selectedCinemaId != null && _selectedShowtime != null)
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SeatSelectionScreen(
                        movieTitle: widget.movieTitle,
                        showtime: _selectedShowtime!,
                      ),
                    ),
                  );
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            disabledBackgroundColor: Colors.grey.shade800,
          ),
          child: const Text('Chọn ghế'),
        ),
      ),
    );
  }

  Widget _buildCinemaAndShowtimeList(
      List<Showtime> showtimes, List<Cinema> allCinemas) {
    final showtimesByCinemaId = groupBy(showtimes, (Showtime s) => s.cinemaId);
    final cinemasWithShowtimes = allCinemas
        .where((cinema) => showtimesByCinemaId.containsKey(cinema.id))
        .toList();

    if (cinemasWithShowtimes.isEmpty) {
      return const Center(
        child: Text(
          'Không có rạp nào có suất chiếu cho ngày này.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100.0),
      itemCount: cinemasWithShowtimes.length,
      itemBuilder: (context, index) {
        final cinema = cinemasWithShowtimes[index];
        final showtimesForThisCinema = showtimesByCinemaId[cinema.id] ?? [];
        final isSelected = _selectedCinemaId == cinema.id;
        return Card(
          color: isSelected ? Colors.grey.shade700 : Colors.grey.shade800,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
                color: isSelected ? Colors.redAccent : Colors.transparent,
                width: 2),
          ),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => setState(() {
                    _selectedCinemaId = cinema.id;
                    _selectedShowtime = null; 
                  }),
                  child: Text(cinema.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ),
                if (isSelected) ...[
                  const SizedBox(height: 16),
                  _buildShowtimePicker(showtimesForThisCinema),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateSelector() {
    final today = DateTime.now();
    final days = List.generate(7, (index) => today.add(Duration(days: index)));

    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
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
                setState(() {
                  _selectedDate = date;
                  _selectedCinemaId = null;
                  _selectedShowtime = null;
                });
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

  Widget _buildShowtimePicker(List<Showtime> times) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: times.map((showtime) {
        final isSelected = _selectedShowtime?.id == showtime.id;
        return ChoiceChip(
          label: Text(DateFormat('HH:mm').format(showtime.startTime)),
          selected: isSelected,
          onSelected: (selected) =>
              setState(() => _selectedShowtime = selected ? showtime : null),
          backgroundColor: Colors.grey.shade800,
          selectedColor: Colors.redAccent,
          labelStyle: const TextStyle(color: Colors.white),
        );
      }).toList(),
    );
  }
}
