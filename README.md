# 🎬 Cinema 4TK

> Ứng dụng đặt vé xem phim hiện đại — tích hợp thanh toán MoMo, xây dựng bằng Flutter & Firebase.  
> A modern movie ticket booking app — integrated with MoMo payment, built with Flutter & Firebase.

---

## 🌟 Giới thiệu | Introduction

**Cinema 4TK** là ứng dụng giúp người dùng:
- Đặt vé xem phim nhanh chóng, trực quan.
- Chọn ghế, suất chiếu, và rạp yêu thích dễ dàng.
- Thanh toán tiện lợi qua **MoMo**.
- Quản lý lịch sử đặt vé, voucher, và tài khoản cá nhân.
- Tích hợp **Riverpod** để quản lý trạng thái linh hoạt, ổn định.

> **Cinema 4TK** allows users to:
> - Quickly and visually book movie tickets.
> - Choose seats, showtimes, and cinemas easily.
> - Make seamless payments via **MoMo**.
> - Manage ticket history, vouchers, and profile.
> - Use **Riverpod** for robust and reactive state management.

---

## 🧱 Công nghệ sử dụng | Tech Stack

| Thành phần | Công nghệ |
|-------------|------------|
| Frontend | Flutter |
| Backend | Firebase Firestore |
| Authentication | Firebase Auth |
| State Management | Riverpod |
| Payment Gateway | MoMo API |
| Cloud Storage | Firebase Storage |
| Analytics | Firebase Analytics |

---

## 🧭 Cấu trúc chính | Project Structure

lib/
├─ main.dart # Điểm khởi chạy chính
├─ screens/ # Các màn hình UI
├─ models/ # Các model dữ liệu (Movie, Ticket, Cinema...)
├─ providers/ # Riverpod providers
├─ services/ # Firebase + Business logic
├─ utils/ # Cấu hình, theme, helper functions
└─ widgets/ # Thành phần UI tái sử dụng

---

## 💳 Thanh toán MoMo | MoMo Payment Integration

Ứng dụng tích hợp **MoMo SDK** để thanh toán trực tiếp trong app, hỗ trợ:
- Giao dịch an toàn, xác thực nhanh.
- Thông báo trạng thái thanh toán (thành công/thất bại).
- Lưu lịch sử giao dịch trên Firebase.

> Integrated **MoMo SDK** for secure in-app payments with real-time status tracking and Firebase storage.

---

🧑‍💻 Đối tượng sử dụng | Target Users
Dự án được phát triển bởi sinh viên Công nghệ Thông tin, phục vụ mục tiêu học tập, nghiên cứu và trình diễn kỹ năng lập trình di động hiện đại với Flutter & Firebase.

Developed by Computer Science students — for learning, experimentation, and showcasing modern Flutter app development skills.
