import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:path_provider/path_provider.dart';

/// The folder under the app support directory that holds every Hive box.
/// Android backups exclude it (`res/xml/backup_rules.xml` and
/// `res/xml/data_extraction_rules.xml`): the encrypted boxes' key never
/// leaves the device.
const String hiveDirectoryName = 'hive';

Future<void> initHive() async {
  if (!kIsWeb) {
    final String directory = (await getApplicationSupportDirectory()).path;
    Hive.init('$directory/$hiveDirectoryName');
  }
  await Hive.openBox<String>(prefsBoxName);
}
