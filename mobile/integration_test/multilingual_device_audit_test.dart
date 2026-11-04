import 'package:integration_test/integration_test.dart';

import '../test/ui_design_inventory_test.dart' as inventory;

// Run only with CHESSVERSE_UI_TEST=true: this mounts fixture screens and uses
// mock secure storage, without modifying the installed production app's data.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  inventory.main(deviceAudit: true);
}
