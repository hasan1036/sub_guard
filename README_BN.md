# SubGuard — চালানোর নিয়ম

এটা অ্যাপের প্রথম ভার্সন (MVP)। এতে আছে:
- জনপ্রিয় ৩৭টা সার্ভিসের তালিকা থেকে এক ট্যাপে সাবস্ক্রিপশন যোগ করা, অথবা নিজের মতো যোগ করা
- ড্যাশবোর্ড: মাসে আর বছরে মোট কত খরচ হচ্ছে, সামনের ৩০ দিনে কত কাটবে, এ বছর কত খরচ হয়েছে
- Upcoming ট্যাব: সামনের ৭ দিন / ৩০ দিন / ৯০ দিন / ১ বছরে কোন তারিখে কত টাকা কাটবে
- History ট্যাব: আগের সব পেমেন্ট মাস অনুযায়ী (বিলিং তারিখ পার হলে নিজে থেকে যোগ হয়)
- ফ্রি ট্রায়াল গার্ড: ট্রায়াল শেষ হওয়ার আগে সতর্কতা
- টাকা কাটার ০/১/২/৩/৭ দিন আগে নোটিফিকেশন (সকাল ৯টায়)
- বাতিলের পেজ এক ট্যাপে খোলা
- ২০টা মুদ্রা, লাইট/ডার্ক মোড
- ফ্রি প্ল্যানে ৫টা সাবস্ক্রিপশন, তারপর প্রিমিয়াম পেজ ($4.99/মাস, $34.99/বছর)
- সব ডেটা শুধু ফোনে থাকে, কোনো সার্ভার বা ব্যাংক লিংক নেই

---

## ধাপ ১: Flutter ইনস্টল
https://docs.flutter.dev/get-started/install থেকে Flutter ইনস্টল করুন (3.44 বা নতুন ভার্সন লাগবে)।
তারপর টার্মিনালে চালান:
```
flutter doctor
```
যেগুলোতে ✗ দেখায় সেগুলো ঠিক করুন (Android Studio, Android SDK ইত্যাদি)।

## ধাপ ২: নতুন প্রজেক্ট বানান
```
flutter create --org com.yourname subguard
```
`com.yourname` বদলে আপনার নিজের কিছু দিন, যেমন `com.hasan`। এটা পরে বদলানো কঠিন।

## ধাপ ৩: এই কোড বসান
এই zip-এর ভেতরের জিনিসগুলো নতুন `subguard` ফোল্ডারে কপি করুন:
- `lib/` ফোল্ডার: পুরোনোটা মুছে এটা বসান
- `test/` ফোল্ডার: পুরোনোটা মুছে এটা বসান
- `pubspec.yaml`: পুরোনোটা বদলে এটা বসান

তারপর চালান:
```
cd subguard
flutter pub get
```

## ধাপ ৪: Android সেটআপ (নোটিফিকেশনের জন্য জরুরি)

**৪.১** `android/app/build.gradle.kts` ফাইল খুলুন। `android { ... }` ব্লকের ভেতরে এগুলো মিলিয়ে নিন:
```kotlin
android {
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // আগের লাইনগুলো থাকবে, শুধু এটা যোগ করুন
        multiDexEnabled = true
    }
}
```
ফাইলের একদম শেষে যোগ করুন:
```kotlin
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

**৪.২** `android/app/src/main/AndroidManifest.xml` খুলুন।

`<application` লাইনের **আগে** যোগ করুন:
```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

`<application ...>` এর **ভেতরে** (`</application>` এর ঠিক আগে) যোগ করুন:
```xml
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON" />
        <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
    </intent-filter>
</receiver>
```

**৪.৩** বিল্ডে যদি `compileSdk` বা Android Gradle Plugin-এর ভার্সন নিয়ে এরর আসে, এররে যে ভার্সন চাইছে সেটা বসান। নোটিফিকেশন প্যাকেজের নতুন ভার্সন compileSdk 37 আর AGP 9.1.1 বা নতুন চায়।

## ধাপ ৫: চালান
ফোন USB দিয়ে যুক্ত করুন (Developer options → USB debugging চালু করে), অথবা Android emulator চালু করুন। তারপর:
```
flutter run
```
টেস্ট চালাতে:
```
flutter test
```

## ধাপ ৬: অ্যাপের নাম বদলানো
- কোডে: `lib/state/app_state.dart` ফাইলে `appName`
- ফোনের হোম স্ক্রিনে: `android/app/src/main/AndroidManifest.xml` এ `android:label`

---

## ফাইলগুলো কী করে
| ফাইল | কাজ |
|---|---|
| `lib/main.dart` | অ্যাপ শুরু, থিম |
| `lib/models/subscription.dart` | সাবস্ক্রিপশনের ডেটা, তারিখ আর খরচের হিসাব |
| `lib/data/catalog.dart` | জনপ্রিয় সার্ভিসের তালিকা আর বাতিলের লিংক |
| `lib/state/app_state.dart` | অ্যাপের সব ডেটা আর লজিক |
| `lib/services/storage.dart` | ফোনে ডেটা সেভ |
| `lib/services/notifications.dart` | রিমাইন্ডার |
| `lib/screens/` | সব স্ক্রিন |

## এর পরের ধাপ
1. **পেমেন্ট:** RevenueCat (`purchases_flutter` প্যাকেজ) যুক্ত করা। `paywall_screen.dart`-এ TODO দেওয়া আছে।
2. **AI স্ক্যান:** স্ক্রিনশট বা রসিদ থেকে স্বয়ংক্রিয়ভাবে সাবস্ক্রিপশন বের করা।
3. **রিলিজের আগে:** Settings-এর "Developer: simulate Premium" সুইচটা মুছে ফেলুন, আর `catalog.dart`-এর বাতিলের লিংকগুলো একবার যাচাই করুন।
