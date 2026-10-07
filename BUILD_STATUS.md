# 📍 สถานะ Build ณ ขณะนี้ (ค้างที่ขั้นตอนที่ 5)

> **อัปเดตล่าสุด**: 5 ตุลาคม 2569  
> **โฟลเดอร์ทำงาน**: `C:\gold-app` (copy จาก `C:\Users\DG\Desktop\Claude\แจ้งข่าวทอง\gold-news-alert\mobile_app`)

---

## ✅ สิ่งที่ทำเสร็จแล้ว

| ขั้นตอน | สถานะ | รายละเอียด |
|----------|-------|------------|
| 1. Firebase Project | ✅ สมมติว่าเสร็จ | Project: `gold-news-alert`, Package: `com.goldnews.alert` |
| 2. GitHub Repo + Secret | ✅ สมมติว่าเสร็จ | Repo: `nessshin1748/gold-news-alert`, Secret: `FCM_SERVER_KEY` |
| 3. Push code to GitHub | ✅ สมมติว่าเสร็จ | Branch: `main` |
| 4. GitHub Actions | ✅ สมมติว่าเสร็จ | 2 workflows: Daily Digest + Breaking Alert |

---

## ❌ ค้างอยู่ที่: **ขั้นตอนที่ 5 - Build APK**

### ปัญหา:
```
Flutter version: 3.24.3 (เก่า)
Error: Could not find io.flutter:flutter_embedding_release:36335019a8...
Maven repo: https://download.flutter.io (SSL certificate mismatch)
```

### ไฟล์ที่แก้ไขแล้วใน `C:\gold-app`:

| ไฟล์ | การเปลี่ยนแปลง |
|------|-------------|
| `android/gradlew.bat` | Force JAVA_HOME = `C:\temp\java\jdk-21.0.12.1+1` |
| `android/gradle/wrapper/gradle-wrapper.properties` | Gradle 8.2 |
| `android/build.gradle` | Kotlin 1.9.0, AGP 8.2.0 |
| `android/app/build.gradle` | เพิ่ม maven `https://storage.googleapis.com/download.flutter.io` + flutter_embedding dependency |
| `android/app/src/main/AndroidManifest.xml` | เพิ่ม `xmlns:tools` + `tools:replace="android:exported"` |
| `android/local.properties` | `flutter.sdk=C:/Users/DG/flutter` |
| `android/gradle.properties` | `android.useAndroidX=true` + `android.enableJetifier=true` |
| `lib/main.dart` | ย้าย `import "dart:convert";` ขึ้นบนสุด |
| `android/app/src/main/res/` | สร้าง mipmap icons + styles.xml + launch_background.xml |

### Java ที่ติดตั้ง:
- `C:\temp\java\jdk-21.0.12.1+1` (Microsoft JDK 21)

---

## 🔧 วิธีแก้ (ลองตามลำดับ)

### 1. ลอง build debug ก่อน (เร็วกว่า error น้อยกว่า)
```powershell
cd C:\gold-app
$env:FLUTTER_ROOT = "C:\Users\DG\flutter"
$env:PATH = "$env:FLUTTER_ROOT\bin;$env:PATH"
flutter build apk --debug
```

### 2. ถ้า debug ผ่าน → ติดตั้งทดสอบได้เลย
APK จะอยู่ที่: `C:\gold-app\build\app\outputs\flutter-apk\app-debug.apk`

### 3. ถ้าอยากได้ release build → upgrade Flutter ก่อน
```powershell
flutter upgrade
flutter pub get
flutter build apk --release
```

---

## 📱 หลัง Build สำเร็จ (ขั้นตอนที่ 6-7)

### 6. ติดตั้งบนมือถือ
- ส่ง `app-debug.apk` หรือ `app-release.apk` ไปมือถือ (Line/Drive/USB)
- ติดตั้ง → เปิดแอป → ควรเห็น **"Notifications Active"**

### 7. ทดสอบ Notification (Manual Trigger)
1. เข้า GitHub → Actions → `Gold News - Daily Digest` → Run workflow
2. รอ 1-2 นาที → มือถือควรได้ Notification

---

## 📞 ถ้าติดขั้นไหน
ส่ง error log มาให้ดูครับ - จะได้ต่อจากตรงนี้เลยตอนเย็น