import 'package:get/get.dart';

import '../controllers/promotion_controller.dart';

class PromotionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PromotionController>(
      () => PromotionController(),
    );
  }
}
