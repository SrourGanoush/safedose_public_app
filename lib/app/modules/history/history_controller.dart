import 'package:get/get.dart';
import '../../data/services/local_history_service.dart';

class HistoryController extends GetxController {
  final LocalHistoryService _historyService = Get.find<LocalHistoryService>();

  List<ScanRecord> get records => _historyService.records;

  Future<void> clearHistory() async {
    await _historyService.clearHistory();
  }
}
