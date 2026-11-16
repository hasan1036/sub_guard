# অ্যাপ আইকন এক কমান্ডে বসানো

ফাইল হাতে কপি করার দরকার নেই। `flutter_launcher_icons` টুল সব সাইজের আইকন নিজে বানিয়ে ঠিক জায়গায় বসিয়ে দেবে।

## ধাপ ১: ছবি দুটো বসান

প্রজেক্টের মূল ফোল্ডারে (যেখানে `pubspec.yaml` আছে) এই zip-এর `assets` ফোল্ডারটা কপি করুন।
শেষে এমন হবে:
```
subguard/
├── assets/
│   └── icon/
│       ├── icon.png
│       └── foreground.png
├── lib/
├── pubspec.yaml
```

## ধাপ ২: pubspec.yaml-এ যোগ করুন

**(ক)** `dev_dependencies:` অংশে একটা লাইন যোগ করুন:
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints:
  flutter_launcher_icons:
```

**(খ)** ফাইলের **একদম শেষে** (বাম দিকে কোনো ফাঁকা জায়গা ছাড়া) যোগ করুন:
```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/icon.png"
  adaptive_icon_background: "#5E2DE6"
  adaptive_icon_foreground: "assets/icon/foreground.png"
  remove_alpha_ios: true
```

## ধাপ ৩: Terminal-এ চালান

```
flutter pub get
dart run flutter_launcher_icons
```
শেষে `✓ Successfully generated launcher icons` দেখালে কাজ হয়ে গেছে।
(এতে iPhone-এর আইকনও তৈরি হয়ে যাবে, পরে কাজে লাগবে।)

## ধাপ ৪: ফোনে দেখুন

1. ফোন থেকে SubGuard **uninstall** করুন (Xiaomi পুরোনো আইকন মনে রাখে)
2. Android Studio-তে **■ Stop → ▶ Run**
3. তারপরও পুরোনো আইকন দেখালে ফোন একবার রিস্টার্ট দিন

আগে হাতে কপি করা `mipmap-anydpi-v26` ফোল্ডার বা `ic_launcher_*.xml` ফাইল থাকলে টুলটা সেগুলো নিজেই নতুন করে লিখে দেবে, মুছতে হবে না।
নোটিফিকেশনের `ic_stat_subguard.xml` যেমন আছে থাকবে, ওটা আলাদা।
