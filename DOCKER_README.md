# Hướng dẫn cài đặt Moodle với Docker

## Cấu hình

Hệ thống bao gồm 3 services:
- **Moodle**: http://localhost:9000
- **MySQL**: localhost:9001
- **phpMyAdmin**: http://localhost:9002

## Yêu cầu

- Docker
- Docker Compose

## Cài đặt

### 1. Chỉnh sửa file .env (nếu cần)

Mở file `.env` và thay đổi thông tin đăng nhập database:

```env
MYSQL_ROOT_PASSWORD=rootpassword
MYSQL_DATABASE=moodle
MYSQL_USER=moodleuser
MYSQL_PASSWORD=moodlepassword
```

### 2. Khởi động Docker containers

```bash
docker-compose up -d
```

### 3. Cài đặt Moodle

Sau khi containers đã chạy, truy cập:
- http://localhost:9000

Làm theo hướng dẫn cài đặt Moodle với thông tin database:
- **Database type**: MySQL (mysqli)
- **Database host**: mysql
- **Database name**: moodle (hoặc giá trị trong .env)
- **Database user**: moodleuser (hoặc giá trị trong .env)
- **Database password**: moodlepassword (hoặc giá trị trong .env)
- **Database port**: 3306

### 4. Truy cập phpMyAdmin

- URL: http://localhost:9002
- Server: mysql
- Username: root
- Password: rootpassword (hoặc giá trị MYSQL_ROOT_PASSWORD trong .env)

## Các lệnh hữu ích

### Xem logs
```bash
docker-compose logs -f
```

### Dừng containers
```bash
docker-compose down
```

### Dừng và xóa tất cả dữ liệu
```bash
docker-compose down -v
```

### Khởi động lại
```bash
docker-compose restart
```

### Build lại image
```bash
docker-compose build --no-cache
docker-compose up -d
```

## Lưu ý

- Dữ liệu MySQL được lưu trong volume `mysql_data`
- Dữ liệu Moodle được lưu trong volume `moodle_data`
- File cấu hình Moodle sẽ được tạo tại `public/config.php` sau khi cài đặt
- Thay đổi mật khẩu trong file `.env` trước khi chạy lần đầu tiên
