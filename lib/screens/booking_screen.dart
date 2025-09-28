import 'package:cinema_app_flutter/screens/seat_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookingScreen extends StatefulWidget {
  final int movieId;
  final String movieTitle;

  const BookingScreen({
    super.key,
    required this.movieId,
    required this.movieTitle,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  // --- Dữ liệu giả mô phỏng dữ liệu từ Backend ---
  final List<Map<String, dynamic>> _showData = [
    {
      "city": "TP. Hồ Chí Minh",
      "cinemas": [
        {
          "name": "Galaxy Nguyễn Du",
          "showtimes": {"2D": ["18:00", "20:30", "22:00"], "3D": ["19:00", "21:30"]}
        },
        {"name": "BHD Star Bitexco", "showtimes": {"2D": ["17:30", "21:00"], "IMAX": ["20:00", "22:30"]}},
      ]
    },
    {
      "city": "Hà Nội",
      "cinemas": [
        {"name": "CGV Vincom Bà Triệu", "showtimes": {"2D": ["18:15", "19:45", "21:30"], "3D": ["19:30", "22:15"]}},
        {"name": "Lotte Cinema Thăng Long", "showtimes": {"2D": ["19:00", "20:45"]}},
      ]
    }
  ];

  // --- Biến state để lưu lựa chọn của người dùng ---
  DateTime? _selectedDate;
  String? _selectedCity;
  Map<String, dynamic>? _selectedCinema;
  String? _selectedTime;
  
  // Danh sách rạp tương ứng với thành phố đã chọn
  List<Map<String, dynamic>> _cinemasInSelectedCity = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }
  
  // Hàm cập nhật danh sách rạp khi thành phố thay đổi
  void _updateCinemasForCity(String city) {
    setState(() {
      _selectedCity = city;
      // Tìm và lấy danh sách rạp
      _cinemasInSelectedCity = _showData
          .firstWhere((data) => data['city'] == city)['cinemas'];
      // Reset các lựa chọn cũ
      _selectedCinema = null;
      _selectedTime = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Lấy danh sách các thành phố từ dữ liệu giả
    final List<String> cities = _showData.map((data) => data['city'] as String).toList();

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
            const Text('Chọn ngày', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildDateSelector(),
            const SizedBox(height: 24),
            _buildCitySelector(cities), // Widget chọn thành phố
            const SizedBox(height: 24),
            // Chỉ hiển thị phần chọn rạp và suất chiếu khi đã chọn thành phố
            if (_selectedCity != null)
              Expanded(
                child: _buildCinemaList(),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: (_selectedDate != null && _selectedTime != null)
    ? () {
        // ✅ CHUYỂN SANG MÀN HÌNH CHỌN GHẾ
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SeatSelectionScreen(
              movieTitle: widget.movieTitle,
              cinemaName: _selectedCinema?['name'] ?? 'N/A',
              date: _selectedDate!,
              time: _selectedTime!,
            ),
          ),
        );
      }
    : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            disabledBackgroundColor: Colors.grey.shade800,
          ),
          child: const Text('Chọn ghế'),
        ),
      ),
    );
  }

  // Widget chọn thành phố
  Widget _buildCitySelector(List<String> cities) {
    return DropdownButtonFormField<String>(
      value: _selectedCity,
      hint: const Text('Chọn thành phố', style: TextStyle(color: Colors.white70)),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade800,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      dropdownColor: Colors.grey.shade800,
      style: const TextStyle(color: Colors.white),
      items: cities.map((String city) {
        return DropdownMenuItem<String>(value: city, child: Text(city));
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          _updateCinemasForCity(newValue);
        }
      },
    );
  }
  
  // Widget hiển thị danh sách rạp
  Widget _buildCinemaList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Chọn rạp và suất chiếu', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: _cinemasInSelectedCity.length,
            itemBuilder: (context, index) {
              final cinema = _cinemasInSelectedCity[index];
              final bool isSelected = _selectedCinema?['name'] == cinema['name'];

              return Card(
                color: isSelected ? Colors.grey.shade700 : Colors.grey.shade800,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: isSelected ? Colors.redAccent : Colors.transparent, width: 2),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCinema = cinema;
                            _selectedTime = null; // Reset giờ khi chọn rạp mới
                          });
                        },
                        child: Text(
                          cinema['name'],
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(height: 16),
                        ..._buildShowtimeList(cinema['showtimes']),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Hàm xây dựng danh sách suất chiếu
  List<Widget> _buildShowtimeList(Map<String, dynamic> showtimes) {
    // Chuyển đổi Map<String, dynamic> thành Map<String, List<String>>
    final castedShowtimes = showtimes.map(
      (key, value) => MapEntry(key, List<String>.from(value)),
    );

    return castedShowtimes.entries.map((entry) {
      return _buildShowtimeCategory(entry.key, entry.value);
    }).toList();
  }

  // Widget xây dựng khu vực chọn suất chiếu cho từng loại (2D, 3D...)
  Widget _buildShowtimeCategory(String format, List<String> times) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          format,
          style: TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: times.map((time) {
            final isSelected = _selectedTime == time;
            return ChoiceChip(
              label: Text(time),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedTime = selected ? time : null;
                });
              },
              backgroundColor: Colors.grey.shade800,
              selectedColor: Colors.redAccent,
              labelStyle: TextStyle(color: Colors.white),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade700),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // Widget chọn ngày
  Widget _buildDateSelector() {
    // Hiển thị 7 ngày liên tiếp từ ngày hiện tại
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
          final isSelected = _selectedDate != null &&
              date.year == _selectedDate!.year &&
              date.month == _selectedDate!.month &&
              date.day == _selectedDate!.day;

          return ChoiceChip(
            label: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('E', 'vi').format(date), // Thứ
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  DateFormat('dd/MM').format(date), // Ngày/tháng
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                _selectedDate = date;
              });
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