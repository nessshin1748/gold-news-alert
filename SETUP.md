# 📱 คู่มือติดตั้ง Gold News Alert (สำหรับคนรู้ศูนย์)

> **ระบบแจ้งเตือนข่าว ForexFactory USD แดง/ส้ม ที่มีผลต่อทองคำ (XAU/USD)**
> - 📅 **Daily Digest**: สรุปข่าววันนี้ ทุกวัน 06:00 น.
> - ⚡ **Breaking Alert**: แจ้งทันทีเวลามีข่าวแดง/ส้มปลดปล่อย (เช็คทุก 15 นาที)
> - 🔔 **Push Notification**: ขึ้นบนหน้าจอมือถือได้เลย (ไม่ต้องเปิดแอป)
> - 💰 **ค่าใช้จ่าย**: **ฟรี 100%** (GitHub Actions + Firebase Spark Plan)

---

## 📋 สิ่งที่ต้องมีก่อนเริ่ม

| สิ่งที่ต้องมี | สถานะ |
|--------------|-------|
| ✅ Google Account (Gmail) | คุณมีแล้ว |
| ✅ GitHub Account | Username: `nessshin1748` |
| ✅ Flutter ติดตั้งแล้ว | `flutter doctor` ✅ |
| 📱 โทรศัพท์ Android (รุ่นใหม่พอสมควร) | เพื่อทดสอบ |

---

## 🎯 ภาพรวมขั้นตอน (5 ขั้นตอน)

```
1. สร้าง Firebase Project + เอา google-services.json + Server Key
2. สร้าง GitHub Repository + ใส่ Secrets
3. Push โค้ดขึ้น GitHub (GitHub Actions จะรันอัตโนมัติ)
4. Build APK บนคอมพิวเตอร์ + ติดตั้งบนมือถือ
5. ทดสอบว่ารับ Notification ได้จริง
```

**เวลาประมาณ: 30-45 นาที**

---

## 🔥 ขั้นตอนที่ 1: สร้าง Firebase Project (สำคัญที่สุด)

### 1.1 เข้า Firebase Console
1. เปิดเว็บ: https://console.firebase.google.com/
2. ล็อกอินด้วย **Gmail เดียวกับที่จะใช้ GitHub**
3. กดปุ่ม **"Add project"** (เพิ่มโปรเจกต์)

### 1.2 ตั้งค่าโปรเจกต์
- **Project name**: `gold-news-alert` (พิมพ์ตรงนี้เลย)
- **Google Analytics**: **ปิด** (Disabled) → ไม่ต้องใช้
- กด **"Create project"** → รอ 1-2 นาที → กด **"Continue"**

### 1.3 เพิ่ม Android App ⭐ (ขั้นตอนสำคัญมาก)
1. หน้า Project Overview → กดไอคอน **Android** (สัญลักษณ์หุ่นยนต์สีเขียว `</>`)
2. **Android package name**: `com.goldnews.alert` ⚠️ **ต้องพิมพ์ตรงนี้ทุกตัวอักษร**
3. **App nickname**: `Gold News Alert`
4. **Debug signing certificate SHA-1**: **เว้นว่างไว้** (ไม่ต้องกรอก)
5. กด **"Register app"**

### 1.4 ดาวน์โหลด google-services.json ⭐
1. จะเห็นปุ่ม **"Download google-services.json"** → กดดาวน์โหลด
2. **ย้าย/คัดลอก** ไฟล์นี้ไปทับที่:
   ```
   C:\Users\DG\Desktop\Claude\แจ้งข่าวทอง\gold-news-alert\mobile_app\android\app\google-services.json
   ```
   (ทับไฟล์ตัวอย่างที่อยู่ในโฟลเดอร์)
3. กด **"Next"** → **"Next"** → **"Continue to console"**

### 1.5 เอา Server Key (FCM Server Key) ⭐
1. ใน Firebase Console → กด **ไอคอนเฟือง (⚙️ Project settings)** มุมซ้ายบน
2. เลือกแท็บ **"Cloud Messaging"**
3. หา **"Server key"** หรือ **"Legacy server key"** → กด **"Copy"** 
4. **เก็บไว้ก่อน** (จะได้มาเป็น string ยาวประมาณ `AAAAxxxx:BBBB...`) 
   > ⚠️ **อย่าให้ใครเห็น key นี้** จะใช้ส่ง Push Notification

---

## 🐙 ขั้นตอนที่ 2: สร้าง GitHub Repository + Secrets

### 2.1 สร้าง Repository ใหม่
1. เข้า: https://github.com/new
2. **Repository name**: `gold-news-alert`
3. **Public** (เลือก Public เพื่อให้ GitHub Actions ฟรี)
4. **ไม่ต้อง** ติ๊ก Add README / .gitignore / License
5. กด **"Create repository"**

### 2.2 ใส่ GitHub Secrets ⭐ (สำคัญมาก - ไม่ใส่ระบบจะไม่ส่ง Notif ได้)
1. ใน Repository ที่เพิ่งสร้าง → กดแท็บ **"Settings"** (เมนูบนสุด)
2. เมนูซ้าย → **"Secrets and variables"** → **"Actions"**
3. กด **"New repository secret"** (ปุ่มสีเขียวขวามือ)
   - **Name**: `FCM_SERVER_KEY` (พิมพ์ใหญ่เล็กตรงนี้)
   - **Secret**: **วาง Server Key ที่ Copy จาก Firebase มา** (string ยาว AAAA...)
4. กด **"Add secret"**

✅ ถ้าทำถูกต้อง จะเห็น `FCM_SERVER_KEY` ในรายการ Secrets

---

## 📤 ขั้นตอนที่ 3: Push โค้ดขึ้น GitHub

### วิธี A: Command Line (แนะนำ - เร็วที่สุด)
เปิด **PowerShell** (ไม่ต้อง Run as Admin) → รันทีละคำสั่ง:

```powershell
cd C:\Users\DG\Desktop\Claude\แจ้งข่าวทอง\gold-news-alert
git init
git add .
git commit -m "Initial commit: Gold News Alert system"
git branch -M main
git remote add origin https://github.com/nessshin1748/gold-news-alert.git
git push -u origin main
```

> **ถ้าขอ username/password**: ใช้ **Personal Access Token** (ไม่ใช่ password GitHub)
> - สร้างที่: https://github.com/settings/tokens → Generate new token (classic) → ติ๊ก `repo` → Copy token ใช้แทน password

### วิธี B: GitHub Desktop (GUI - ใช้เมาส์)
1. ดาวน์โหลด: https://desktop.github.com/ → ติดตั้ง → ล็อกอิน
2. **File** → **Add Local Repository** → Browse เลือกโฟลเดอร์:
   `C:\Users\DG\Desktop\Claude\แจ้งข่าวทอง\gold-news-alert`
3. กด **"Publish repository"** → ติ๊ก **Keep this code private** → **Publish Repository**

---

## ⚙️ ขั้นตอนที่ 4: ตรวจสอบ GitHub Actions รันอัตโนมัติ

หลัง Push เสร็จ:
1. เข้า Repository บน GitHub → กดแท็บ **"Actions"**
2. จะเห็น 2 workflows:
   - `Gold News - Daily Digest (06:00 Bangkok)`
   - `Gold News - Breaking Alert (Every 15 min)`
3. รอดูว่า status เป็น **สีเขียว (✅)** หรือ **สีแดง (❌)**
   - ถ้าแดง → กดดู error log → ส่งมาให้ผมดู
   - ถ้าเขียว → ระบบพร้อมทำงานแล้ว!

> **หมายเหตุ**: GitHub Actions ฟรี 2,000 นาที/เดือน → พอใช้สำหรับระบบนี้ (ใช้ ~30 นาที/เดือน)

---

## 📱 ขั้นตอนที่ 5: Build APK + ติดตั้งบนมือถือ

### 5.1 Build APK
เปิด **PowerShell** → รัน:

```powershell
cd C:\Users\DG\Desktop\Claude\แจ้งข่าวทอง\gold-news-alert\mobile_app
flutter pub get
flutter build apk --release
```

- รอ 2-5 นาที (ครั้งแรกนานกว่า เพราะดาวน์โหลด dependencies)
- ข้อความ `Built build/app/outputs/flutter-apk/app-release.apk` = สำเร็จ

### 5.2 หาไฟล์ APK
อยู่ที่:
```
C:\Users\DG\Desktop\Claude\แจ้งข่าวทอง\gold-news-alert\mobile_app\build\app\outputs\flutter-apk\app-release.apk
```

### 5.3 ส่ง APK ไปมือถือ (เลือกวิธีใดวิธีหนึ่ง)
| วิธี | คำอธิบาย |
|------|----------|
| **Line/Telegram** | ส่งไฟล์ `.apk` ให้ตัวเอง → เปิดบนมือถือดาวน์โหลด |
| **Google Drive** | อัปโหลด → แชร์ลิงก์ → เปิดบนมือถือดาวน์โหลด |
| **USB Cable** | Copy ไฟล์ไปโฟลเดอร์ Download ของมือถือ |

### 5.4 ติดตั้งบนมือถือ
1. เปิดไฟล์ `app-release.apk` บนมือถือ
2. ถ้าบอก **"Install unknown apps"** → Settings → อนุญาตแอปที่ใช้ติดตั้ง (Line/Chrome/Files) → กลับมา Install ใหม่
3. รอติดตั้งเสร็จ → กด **"Open"**

### 5.5 เปิดแอปครั้งแรก
- จะเห็นหน้าจอ **"Gold News Alert"**
- **FCM Token**: string ยาว (คัดลอกได้ แต่ไม่จำเป็น)
- **สถานะ**: "Notifications Active" ✅
- **Recent Alerts**: "No alerts yet" (ปกติครั้งแรก)

> ✅ ถ้าเห็น "Notifications Active" = **พร้อมรับ Notification แล้ว!**

---

## ✅ ขั้นตอนที่ 6: ทดสอบระบบ (Manual Trigger)

### ทดสอบ Daily Digest (สรุปข่าวประจำวัน)
1. เข้า GitHub Repository → **Actions** → `Gold News - Daily Digest`
2. กด **"Run workflow"** (ปุ่มขวามือ) → **Run workflow** (สีเขียว)
3. รอ 1-2 นาที → ดู status สีเขียว
4. **มือถือควรได้รับ Notification** ประมาณนี้:
   ```
   📅 ข่าวทองวันนี้ (05/10/2025) - 3 รายการ
   🔴 ผลกระทบแรง (High):
     20:30 - Non-Farm Payrolls
     22:00 - FOMC Meeting Minutes
   🟠 ผลกระทบปานกลาง (Medium):
     21:45 - Fed Chair Powell Speaks
   ⚠️ ช่วงเวลาระวัง:
     ⏰ 20:00-21:30 น.
     ⏰ 21:15-23:00 น.
   ```

### ทดสอบ Breaking Alert (ข่าวล่าสุด)
1. เข้า GitHub Repository → **Actions** → `Gold News - Breaking Alert`
2. กด **"Run workflow"** → **Run workflow**
3. รอ 1-2 นาที → ถ้ามีข่าว USD แดง/ส้ม อยู่ → จะได้ Notification แบบนี้:
   ```
   🔴 High Impact: Non-Farm Payrolls
   ⏰ เวลา: 20:30 น.
   📊 ผลกระทบ: High
   🎯 คาดการณ์: 180K
   📈 ก่อนหน้า: 165K
   ⚡ ทองคำอาจเคลื่อนไหวได้รวดเร็ว!
   ```

> **หมายเหตุ**: ถ้าไม่มีข่าวในขณะทดสอบ → จะไม่มี Notif (ปกติ) → ลองดู GitHub Actions log จะเห็น `Found 0 relevant USD events`

---

## 🔧 การตั้งค่าเพิ่มเติม (Optional - ทำได้ทีหลัง)

### เปลี่ยนเวลา "ห้ามแจ้งเตือน" (Do Not Disturb)
ไฟล์: `python/main.py` บรรทัด ~70
```python
def should_suppress_notification() -> bool:
    now = get_bangkok_time()
    return 2 <= now.hour < 6  # ปัจจุบัน: 02:00-06:00 น. ไม่แจ้งเตือน
```
แก้เป็นเวลาที่ต้องการ เช่น `22 <= now.hour or now.hour < 6` = 22:00-06:00

### เพิ่ม/ลด Keywords ข่าวที่เกี่ยวกับทอง
ไฟล์: `python/main.py` บรรทัด ~25 `GOLD_KEYWORDS`
```python
GOLD_KEYWORDS = [
    "non-farm", "nfp", "cpi", "fomc", "fed", "gold", "xau", ...
    # เพิ่ม keyword ใหม่ได้ที่นี่
]
```

### เปลี่ยนความถี่การเช็คข่าว
ไฟล์: `.github/workflows/breaking-alert.yml` บรรทัด `cron`
```yaml
# ปัจจุบัน: ทุก 15 นาที
- cron: "*/15 23-23 * * *"
- cron: "*/15 0-18 * * *"

# เปลี่ยนเป็น 30 นาที:
- cron: "*/30 23-23 * * *"
- cron: "*/30 0-18 * * *"
```

---

## 🛠️ Troubleshooting (แก้ปัญหา)

| ปัญหา | สาเหตุ / วิธีแก้ |
|--------|------------------|
| **Push โค้ด error "Authentication failed"** | ใช้ **Personal Access Token** แทน Password (Settings → Developer settings → Personal access tokens → Generate new token (classic) → ติ๊ก `repo`) |
| **GitHub Actions แดง (Failed)** | กดดู workflow ที่ fail → ดู log error → ส่งข้อความ error มาให้ผม |
| **ไม่ได้รับ Notification** | 1. เช็ค Actions ว่ารันผ่าน (สีเขียว)<br>2. เช็ค `FCM_SERVER_KEY` ใน GitHub Secrets<br>3. เช็ค `google-services.json` อยู่ที่ `mobile_app/android/app/` และ package name `com.goldnews.alert`<br>4. ในแอปมือถือ ดู FCM Token มีค่าหรือไม่ |
| **Flutter build error** | รัน: `flutter clean` → `flutter pub get` → `flutter build apk --release` |
| **"App not installed" บนมือถือ** | 1. ลบแอปเก่าก่อน → ติดตั้งใหม่<br>2. เช็ค Android version ≥ 6.0 (API 23) |
| **Notification ไม่ดัง/ไม่ขึ้น Lock Screen** | 1. Settings → Apps → Gold News Alert → Notifications → เปิดทั้งหมด<br>2. ไม่ได้เปิด Battery optimization สำหรับแอปนี้ |
| **Google-services.json error** | ต้องมี package name `com.goldnews.alert` **ตรงทุกที่**: Firebase Console, `google-services.json`, `android/app/build.gradle`, `AndroidManifest.xml` |

---

## 📁 โครงสร้างไฟล์สำคัญ (ถ้าอยากแก้เอง)

```
gold-news-alert/
├── .github/workflows/
│   ├── breaking-alert.yml      # Schedule: ทุก 15 นาที
│   └── daily-digest.yml        # Schedule: 06:00 น. (23:00 UTC)
├── python/
│   ├── main.py                 # โค้ดหลัก: Scrape + Filter + FCM
│   └── requirements.txt        # Python libraries
├── mobile_app/
│   ├── pubspec.yaml            # Flutter dependencies
│   ├── lib/main.dart           # App UI + FCM + Local Notifications
│   └── android/app/
│       ├── google-services.json # 🔑 ใส่ของคุณ (จาก Firebase)
│       └── src/main/
│           ├── AndroidManifest.xml
│           └── kotlin/com/goldnews/alert/MainActivity.kt
└── SETUP.md                    # ไฟล์นี้
```

---

## 📞 ติดต่อขอความช่วยเหลือ

ถ้าติดขั้นไหน **ส่งข้อมูลนี้มาให้ผม**:

1. **ขั้นตอนที่ติด** (เช่น "ขั้นตอน 1.4", "ขั้นตอน 5.1")
2. **Error message** ทั้งหมด (Copy ทั้งบล็อก หรือสรุป screenshot)
3. **Screenshot** หน้าจอที่ error (ถ้าเป็น GUI)

**ช่องทางติดต่อ**: ส่งข้อความในแชทนี้ต่อเลยครับ

---

## ✅ Checklist สรุป (ติ๊กเมื่อทำเสร็จ)

- [ ] 1.1-1.2: สร้าง Firebase Project `gold-news-alert`
- [ ] 1.3: เพิ่ม Android App package `com.goldnews.alert`
- [ ] 1.4: Download `google-services.json` → วางทับ `mobile_app/android/app/google-services.json`
- [ ] 1.5: Copy **Server Key** จาก Firebase Cloud Messaging
- [ ] 2.1: สร้าง GitHub Repo `gold-news-alert` (Public)
- [ ] 2.2: ใส่ GitHub Secret `FCM_SERVER_KEY` = Server Key จากข้อ 1.5
- [ ] 3: Push โค้ดขึ้น GitHub (Command Line หรือ GitHub Desktop)
- [ ] 4: เช็ค GitHub Actions → ทั้ง 2 workflows เป็นสีเขียว
- [ ] 5.1-5.2: `flutter pub get` → `flutter build apk --release`
- [ ] 5.3-5.4: ส่ง APK ไปมือถือ → Install → เปิดแอปเห็น "Notifications Active"
- [ ] 6: ทดสอบ Run workflow Manual → รับ Notification บนมือถือ

---

**🎉 ทำครบทุกข้อ = ระบบพร้อมใช้งาน 24/7 ฟรีตลอดชีวิต!**

---

> **หมายเหตุ**: ระบบนี้ใช้ **GitHub Actions** (ฟรี 2000 นาที/เดือน) + **Firebase FCM** (ฟรีไม่จำกัด) → ไม่มีค่าใช้จ่ายใดๆ ไม่ต้องใส่บัตรเครดิต
