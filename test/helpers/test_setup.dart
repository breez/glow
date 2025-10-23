import 'package:flutter_test/flutter_test.dart';
import 'package:glow_breez/logging/app_logger.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Fake path provider for tests
class FakePathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async => '/tmp/test_docs';

  @override
  Future<String?> getTemporaryPath() async => '/tmp/test_temp';
}

/// Initialize test environment
/// Call this in setUpAll() of your test files
void initializeTestEnvironment() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  PathProviderPlatform.instance = FakePathProviderPlatform();
}
