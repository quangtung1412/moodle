# Moodle Docker - Quick Start Guide

## 🚀 Cài đặt trong 5 phút

### Bước 1: Clone hoặc CD vào thư mục Moodle

```bash
cd /path/to/moodle
```

### Bước 2: Start Docker containers

```bash
docker-compose up -d --build
```

**Chờ 10-15 phút để:**
- Build Docker image
- Install dependencies
- Create database
- Auto-install Moodle

### Bước 3: Theo dõi quá trình cài đặt

```bash
docker-compose logs -f moodle
```

Đợi cho đến khi thấy:
```
==========================================
Moodle installation completed!
==========================================
Admin credentials:
  Username: admin
  Password: Admin@123
==========================================
```

### Bước 4: Truy cập Moodle

Mở trình duyệt: **http://localhost:9000**

Đăng nhập:
- Username: `admin`
- Password: `Admin@123`

## 🎉 Hoàn thành!

**Services đã sẵn sàng:**
- 🌐 Moodle: http://localhost:9000
- 💾 phpMyAdmin: http://localhost:9002
- 📧 MailHog: http://localhost:9003

## ⚙️ Cấu hình (Optional)

Chỉnh sửa file `.env` TRƯỚC KHI chạy `docker-compose up`:

```env
# Đổi mật khẩu
MYSQL_PASSWORD=your_password
MOODLE_ADMIN_PASSWORD=YourAdminPassword123!

# Đổi domain (production)
MOODLE_WWWROOT=https://yourdomain.com
```

## 📚 Chi tiết

Xem [DOCKER_README.md](DOCKER_README.md) để biết:
- Troubleshooting
- Advanced configuration
- Production deployment
- CLI commands
- Backup & restore

## 🛑 Stop & Remove

```bash
# Stop (giữ data)
docker-compose down

# Stop và xóa TẤT CẢ (including data)
docker-compose down -v
```

## 🔄 Restart

```bash
docker-compose restart
```

## 📋 Requirements

- Docker Desktop hoặc Docker Engine
- 4GB+ RAM
- 10GB+ disk space
