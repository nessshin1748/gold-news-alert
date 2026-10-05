# Gold News Alert - Setup Guide (Thai)

## 📋 สิ่งที่ต้องเตรียม (ทำครั้งเดียว)

### 1. GitHub Account ✅
- Username: `nessshin1748` (คุณมีแล้ว)
- ไปที่ github.com สร้าง repository ใหม่ชื่อ `gold-news-alert` (Public)

### 2. Firebase Project ✅
1. เข้า https://console.firebase.google.com/
2. "Add project" → ชื่อ: `gold-news-alert` → Disable Analytics → Create
3. คลิกไอคอน **Android** (</>) 
   - Package name: `com.goldnews.alert` (สำคัญ: ต้องตรงกัน!)
   - App nickname: `Gold News Alert`
   - **Download `google-services.json`** → วางทับไฟล์ที่ `mobile_app/android/app/google-services.json`
4. ไป **Project Settings** (ไอคอนเฟือง) → **Cloud Messaging** → Copy **Server key** (Server key / Legacy server key)

### 3. GitHub Secrets (สำคัญมาก!)
เข้า GitHub repo → Settings → Secrets and variables → Actions → New repository secret:
- Name: `FCM_SERVER_KEY` 
- Value: **Server key จาก Firebase ข้อ 3**

---

## 🚀 Deploy (รันอัตโนมัติ)

### วิธีที่ 1: Push ไป GitHub (แนะนำ)
```bash
cd C:\Users\DG\Desktop\Claude\แจ้งข่าวทอง\gold-news-alert
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/nessshin1748/gold-news-alert.git
git push -u origin main
```

### วิธีที่ 2: GitHub Desktop (GUI)
1. ดาวน์โหลด GitHub Desktop
2. File → Add local repository → เลือกโฟลเดอร์ `gold-news-alert`
3. Publish repository → Public → Publish

---

## 📱 Build & Install APK บนมือถือ

### ติดตั้ง Flutter (ถ้ายังไม่ได้ทำ)
```powershell
# แล้วคุณทำแล้ว - ข้ามได้
flutter doctor
```

### Build APK
```bash
cd C:\Users\DG\Desktop\Claude\แจ้งข่าวทอง\gold-news-alert\mobile_app
flutter pub get
flutter build apk --release
```

**ไฟล์ APK จะอยู่ที่:** `mobile_app/build/app/outputs/flutter-apk/app-release.apk`

### ติดตั้งบนมือถือ
1. คัดลอก `app-release.apk` ไปมือถือ (ส่งผ่าน Line/Email/USB)
2. เปิดบนมือถือ → Install (อาจต้องอนุญาต "Install unknown apps")
3. เปิดแอป "Gold News Alert" → จะเห็น FCM Token และสถานะ "Notifications Active"

---

## ✅ ทดสอบระบบ

### ทดสอบ Daily Digest (รัน Manual)
1. ไป GitHub → Actions → "Gold News - Daily Digest" → Run workflow
2. รอ 1-2 นาที → มือถือควรได้รับแจ้งเตือน

### ทดสอบ Breaking Alert (รัน Manual)
1. ไป GitHub → Actions → "Gold News - Breaking Alert" → Run workflow
2. รอ 1-2 นาที → มือถือควรได้รับแจ้งเตือน (ถ้ามีข่าวแดง/ส้ม USD อยู่)

---

## ⚙️ ตัวเลือกปรับแต่ง (Optional)

### เปลี่ยนช่วงเวลา Do Not Disturb
แก้ไข `python/main.py`:
```python
def should_suppress_notification() -> bool:
    now = get_bangkok_time()
    return 2 <= now.hour < 6  # เปลี่ยนเป็นเวลาที่ต้องการ
```

### เพิ่ม/ลด Keywords ข่าวทอง
แก้ไข `GOLD_KEYWORDS` ใน `python/main.py`

### เปลี่ยน Schedule GitHub Actions
แก้ไข `cron` ในไฟล์ `.github/workflows/*.yml`:
- Daily: `"0 23 * * *"` = 06:00 Bangkok
- Breaking: `*/15` = ทุก 15 นาที

---

## 🔧 Troubleshooting

| ปัญหา | แก้ไข |
|--------|-------|
| ไม่ได้รับ Notification | 1. เช็ค GitHub Actions ว่ารันผ่าน<br>2. เช็ค FCM_SERVER_KEY ใน Secrets<br>3. เช็ค `google-services.json` package name ตรง `com.goldnews.alert` |
| Flutter build error | `flutter clean` → `flutter pub get` → `flutter build apk` |
| AndroidManifest error | เช็ค package name ใน `android/app/build.gradle` และ `AndroidManifest.xml` ตรง `com.goldnews.alert` |
| GitHub Actions ไม่รัน | เช็คว่า repo เป็น Public และ Actions enabled |

---

## 📞 ขอความช่วยเหลือ
ถ้าติดตรงไหน ส่ง error message มา ผมช่วยดูครับ!
