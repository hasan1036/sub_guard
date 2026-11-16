# SubGuard v1.0: Android রিলিজ গাইড

প্রথম ভার্সন **সম্পূর্ণ ফ্রি**: কোনো পেমেন্ট নেই, কোনো বিজ্ঞাপন নেই।
কোডে `lib/state/app_state.dart` ফাইলে `paymentsEnabled = false` রাখা আছে।
পরে Premium চালু করতে চাইলে এটা `true` করবেন।

---

## ধাপ ১: নতুন কোড আর ফাইল বসান

zip-এর ভেতরে যা আছে আর কোথায় বসাবেন:

| zip-এর ভেতরে | কোথায় বসাবেন |
|---|---|
| `lib/` | প্রজেক্টের `lib/` ফোল্ডারের জায়গায় (পুরোটা বদলে দিন) |
| `android_res/` ফোল্ডারের **ভেতরের সব ফোল্ডার** | `android/app/src/main/res/`-এ। একই নামের ফাইল থাকলে **Replace** দিন |
| `playstore_icon_512.png` | এখন কোথাও বসাতে হবে না, Play Console-এ আপলোড করবেন |
| `PRIVACY_POLICY.md` | এখন কোথাও বসাতে হবে না, ওয়েবে প্রকাশ করবেন (ধাপ ৬) |

`android_res`-এ যা আছে:
- `mipmap-*/ic_launcher.png`: নতুন বেগুনি শিল্ড অ্যাপ আইকন (পুরোনো Flutter আইকনের জায়গায়)
- `mipmap-anydpi-v26/ic_launcher.xml` + `drawable/ic_launcher_*.xml`: নতুন Android ফোনের আইকন (গোল/চৌকো যেকোনো আকারে মানিয়ে যায়)
- `drawable/ic_stat_subguard.xml`, `raw/keep.xml`: নোটিফিকেশন আইকন (আগে বানিয়েছেন, আবার Replace দিলেও সমস্যা নেই)

তারপর **■ Stop → ▶ Run**। ফোনের হোম স্ক্রিনে নতুন বেগুনি আইকন দেখাবে।
আইকন না বদলালে ফোন থেকে অ্যাপটা একবার uninstall করে আবার ▶ চাপুন।

---

## ধাপ ২: ভার্সন নম্বর

`pubspec.yaml` খুলে `version:` লাইনটা এমন করুন:
```yaml
version: 1.0.0+1
```
- `1.0.0` = ইউজার যে ভার্সন দেখবে
- `+1` = Play Store-এর ভেতরের নম্বর। **প্রতিটা নতুন আপলোডে এটা ১ করে বাড়াতে হবে** (+2, +3...)

---

## ধাপ ৩: Application ID চেক করুন (খুব জরুরি)

`android/app/build.gradle.kts` খুলে `applicationId` লাইনটা দেখুন।

- যদি `com.example.subguard` লেখা থাকে, তাহলে **অবশ্যই বদলাতে হবে**। Play Store `com.example` গ্রহণ করে না।
- এটা বদলে নিজের একটা নাম দিন, যেমন:
```kotlin
applicationId = "com.hasan.subguard"
```
- শুধু `applicationId` লাইন বদলাবেন, `namespace` লাইন যেমন আছে তেমন থাকবে।
- **Play Store-এ একবার প্রকাশ হলে এটা আর কখনো বদলানো যায় না।** তাই ভেবেচিন্তে দিন।

বদলানোর পর ফোন থেকে পুরোনো অ্যাপ uninstall করে আবার চালান (ID বদলালে ফোন এটাকে নতুন অ্যাপ ভাবে)।

---

## ধাপ ৪: সাইনিং কী বানান (একবারই করতে হয়)

Play Store-এ আপলোড করা প্রতিটা ফাইলে আপনার ডিজিটাল "সই" লাগে।

**৪.১ কী ফাইল বানান**

Android Studio-র **Terminal**-এ এটা চালান (এক লাইনে):
```
keytool -genkey -v -keystore C:\Users\Hasan\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
- একটা পাসওয়ার্ড চাইবে, দিন আর **কোথাও লিখে রাখুন**।
- নাম, শহর, দেশ জিজ্ঞেস করবে। যা খুশি দিতে পারেন (দেশ: `BD`)।
- শেষে `yes` লিখে Enter।

`keytool` চিনতে না পারলে (`'keytool' is not recognized`), এটা চালান:
```
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkey -v -keystore C:\Users\Hasan\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

⚠️ **`upload-keystore.jks` ফাইল আর পাসওয়ার্ড হারালে অ্যাপ আপডেট করতে ঝামেলা হবে।**
ফাইলটার একটা কপি Google Drive বা পেনড্রাইভে রেখে দিন। কাউকে দেবেন না, GitHub-এ তুলবেন না।

**৪.২ key.properties ফাইল বানান**

`android` ফোল্ডারে (যেখানে `settings.gradle.kts` আছে) নতুন ফাইল বানান: **`key.properties`**
ভেতরে লিখুন (পাসওয়ার্ড দুটো জায়গাতেই আপনার দেওয়া পাসওয়ার্ড):
```
storePassword=আপনার_পাসওয়ার্ড
keyPassword=আপনার_পাসওয়ার্ড
keyAlias=upload
storeFile=C:/Users/Hasan/upload-keystore.jks
```
(পথে `/` ব্যবহার করুন, `\` না)

**৪.৩ build.gradle.kts-এ সাইনিং যোগ করুন**

`android/app/build.gradle.kts` খুলুন।

**(ক)** ফাইলের **একদম উপরে**, `plugins {` এর আগে যোগ করুন:
```kotlin
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```

**(খ)** `android { ... }` ব্লকের ভেতরে, `buildTypes {` এর **আগে** যোগ করুন:
```kotlin
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
```

**(গ)** `buildTypes { release { ... } }`-এর ভেতরে এখন সম্ভবত লেখা আছে:
```kotlin
signingConfig = signingConfigs.getByName("debug")
```
এটা বদলে লিখুন:
```kotlin
signingConfig = signingConfigs.getByName("release")
```

---

## ধাপ ৫: রিলিজ বিল্ড বানান

Terminal-এ:
```
flutter clean
flutter build appbundle
```
সফল হলে ফাইল পাবেন এখানে:
```
build\app\outputs\bundle\release\app-release.aab
```
এই `.aab` ফাইলটাই Play Console-এ আপলোড করবেন।

**আপলোডের আগে রিলিজ ভার্সন ফোনে একবার চালিয়ে দেখুন** (রিলিজ বিল্ড কখনো কখনো debug থেকে আলাদা আচরণ করে):
```
flutter run --release
```
চেক করুন: অ্যাপ খোলে, সাবস্ক্রিপশন যোগ হয়, **Send a test reminder** কাজ করে, নোটিফিকেশনে বেগুনি শিল্ড আইকন আসে।

---

## ধাপ ৬: প্রাইভেসি পলিসি ওয়েবে প্রকাশ

Play Store একটা **পাবলিক লিংক** চায়।
1. `PRIVACY_POLICY.md` খুলে শেষে `[your email address]` জায়গায় আপনার ইমেইল দিন।
2. ফ্রি তে প্রকাশের সহজ উপায়: **sites.google.com** → নতুন সাইট → লেখাটা পেস্ট → **Publish**।
3. পাওয়া লিংকটা Play Console-এ দেবেন।

---

## ধাপ ৭: Play Console

1. **play.google.com/console**-এ ডেভেলপার অ্যাকাউন্ট খুলুন (একবার $25)।
2. **Create app** → নাম: `SubGuard`, Free, App।
3. **Store listing**:
   - Short description (৮০ অক্ষর): `Track subscriptions and get reminded before every charge.`
   - Full description: অ্যাপ কী করে, ফিচার, প্রাইভেসি
   - App icon: `playstore_icon_512.png`
   - Feature graphic: 1024×500 ছবি (পরে বানিয়ে দিতে পারি)
   - স্ক্রিনশট: অন্তত ২টা, ভালো হয় ৪–৮টা (Home, Add, Detail, **নোটিফিকেশন**)
4. **Data safety** ফর্মে উত্তর:
   - Does your app collect or share user data? → **No**
   - (সব ডেটা ফোনে থাকে, কোথাও পাঠানো হয় না)
5. **Ads** → **No, my app does not contain ads**
6. **Content rating** প্রশ্নপত্র পূরণ করুন (সব উত্তর সাধারণত "No")
7. **Target audience** → 18+ বা 13+ বেছে নিন

---

## ধাপ ৮: Closed testing (১২ জন × ১৪ দিন)

নতুন ব্যক্তিগত অ্যাকাউন্টে Production-এ যাওয়ার আগে এটা বাধ্যতামূলক।
1. **Testing → Closed testing** → নতুন track → `.aab` আপলোড।
2. **Testers**: ১৫–২০ জনের Gmail ঠিকানার একটা লিস্ট দিন (১২ জনের বেশি, কারণ কেউ কেউ মাঝপথে বাদ পড়ে)।
3. Google রিভিউ করে অনুমোদন দিলে একটা লিংক পাবেন। লিংকটা টেস্টারদের পাঠান, তারা **opt-in** করে অ্যাপ ইনস্টল করবে।
4. **১৪ দিন টানা** কেউ যেন opt-out না করে। মাঝে মাঝে মনে করিয়ে দিন অ্যাপটা খুলতে।
5. ১৪ দিন পর **Apply for production** → প্রশ্নগুলোর উত্তর বিস্তারিত আর সৎভাবে দিন।

---

## লঞ্চের আগে শেষ চেকলিস্ট

- [ ] নতুন অ্যাপ আইকন ফোনে দেখা যাচ্ছে
- [ ] `version: 1.0.0+1`
- [ ] `applicationId` এ `com.example` নেই
- [ ] `flutter run --release`-এ সব কাজ করছে
- [ ] Settings-এ Premium বা Developer অংশ দেখা যাচ্ছে না
- [ ] বাতিলের লিংকগুলো একবার করে খুলে দেখা হয়েছে
- [ ] অন্তত আরেকটা ব্র্যান্ডের ফোনে (Samsung/Realme) টেস্ট
- [ ] প্রাইভেসি পলিসির লিংক তৈরি
- [ ] `upload-keystore.jks` আর পাসওয়ার্ডের ব্যাকআপ রাখা হয়েছে
