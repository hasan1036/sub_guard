import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Knows which phone brands stop apps in the background, and opens the
/// right settings page so the user can allow SubGuard with one tap.
class DeviceSetup {
  DeviceSetup._();
  static final instance = DeviceSetup._();

  String _brand = '';
  String _maker = '';
  String _package = '';
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      _package = (await PackageInfo.fromPlatform()).packageName;
      if (Platform.isAndroid) {
        final info = await DeviceInfoPlugin().androidInfo;
        _brand = '${info.manufacturer} ${info.brand}'.toLowerCase();
        _maker = info.manufacturer.trim();
      }
    } catch (e) {
      debugPrint('Device info failed: $e');
    }
  }

  bool _has(List<String> names) => names.any(_brand.contains);

  bool get isXiaomi => _has(['xiaomi', 'redmi', 'poco']);
  bool get isOppoFamily => _has(['oppo', 'realme', 'oneplus']);
  bool get isVivo => _has(['vivo', 'iqoo']);
  bool get isHuawei => _has(['huawei', 'honor']);
  bool get isSamsung => _has(['samsung']);
  bool get isTranssion => _has(['tecno', 'infinix', 'itel']);

  /// Brands known to be especially strict with background apps.
  bool get isKnownStrict =>
      isXiaomi || isOppoFamily || isVivo || isHuawei || isSamsung || isTranssion;

  /// Every Android phone gets the battery step: any phone (Walton, Symphony,
  /// Motorola, Nokia, Pixel...) can delay or block reminders to save battery,
  /// and allowing it costs the user nothing.
  bool get needsBackgroundSetup => Platform.isAndroid;

  String get brandLabel {
    if (isXiaomi) return 'Xiaomi';
    if (isOppoFamily) return 'Oppo / Realme';
    if (isVivo) return 'Vivo';
    if (isHuawei) return 'Huawei / Honor';
    if (isSamsung) return 'Samsung';
    if (isTranssion) return 'Tecno / Infinix';
    if (_maker.isNotEmpty) {
      return _maker[0].toUpperCase() + _maker.substring(1).toLowerCase();
    }
    return 'Your phone';
  }

  static const _channel = MethodChannel('subguard/device');

  /// Whether Android already lets SubGuard run without battery limits.
  /// Some brands (Xiaomi...) use their own battery menu that Android does
  /// not report; there this stays false and the user confirms it instead.
  Future<bool> isBatteryUnrestricted() async {
    if (!Platform.isAndroid) return true;
    try {
      return await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations') ??
          false;
    } catch (_) {
      return false; // can't tell: ask, to be safe
    }
  }

  /// Brands with a separate "auto-start" switch page.
  bool get hasAutostart =>
      isXiaomi || isOppoFamily || isVivo || isHuawei || isTranssion;

  /// The name of that switch, as the phone shows it.
  String get autostartLabel {
    if (isOppoFamily) return 'Allow auto launch';
    if (isHuawei) return 'App launch';
    if (isTranssion) return 'Auto-start';
    return 'Autostart';
  }

  /// The battery option to pick, as the phone shows it.
  String get batteryChoice => isXiaomi ? 'No restrictions' : 'Unrestricted';

  /// Where that option is, as the phone shows it.
  String get batteryMenu => isXiaomi ? 'Battery saver' : 'Battery';

  /// Brand "auto-start" screens. Tried in order; the first that exists opens.
  /// If none exists, the normal app settings page opens instead.
  List<AndroidIntent> get _autostartScreens {
    AndroidIntent c(String pkg, String cls) =>
        AndroidIntent(package: pkg, componentName: cls);
    if (isXiaomi) {
      return [
        c('com.miui.securitycenter',
            'com.miui.permcenter.autostart.AutoStartManagementActivity'),
      ];
    }
    if (isOppoFamily) {
      return [
        c('com.coloros.safecenter',
            'com.coloros.safecenter.permission.startup.StartupAppListActivity'),
        c('com.coloros.safecenter',
            'com.coloros.safecenter.startupapp.StartupAppListActivity'),
        c('com.oppo.safe',
            'com.oppo.safe.permission.startup.StartupAppListActivity'),
      ];
    }
    if (isVivo) {
      return [
        c('com.vivo.permissionmanager',
            'com.vivo.permissionmanager.activity.BgStartUpManagerActivity'),
        c('com.iqoo.secure',
            'com.iqoo.secure.ui.phoneoptimize.BgStartUpManager'),
      ];
    }
    if (isHuawei) {
      return [
        c('com.huawei.systemmanager',
            'com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity'),
        c('com.huawei.systemmanager',
            'com.huawei.systemmanager.optimize.process.ProtectActivity'),
      ];
    }
    if (isTranssion) {
      return [
        c('com.transsion.phonemaster',
            'com.cyin.himgr.autostart.AutoStartActivity'),
      ];
    }
    return [];
  }

  Future<bool> _tryLaunch(AndroidIntent intent) async {
    try {
      if (await intent.canResolveActivity() != true) return false;
      await intent.launch();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Opens the brand's auto-start / background page, or app settings.
  Future<void> openBackgroundSettings() async {
    if (!Platform.isAndroid) return;
    for (final intent in _autostartScreens) {
      if (await _tryLaunch(intent)) return;
    }
    await openAppSettings();
  }

  /// SubGuard's own "App info" page (battery, notifications, permissions).
  Future<void> openAppSettings() async {
    if (!Platform.isAndroid || _package.isEmpty) return;
    await _tryLaunch(AndroidIntent(
      action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
      data: 'package:$_package',
    ));
  }
}
