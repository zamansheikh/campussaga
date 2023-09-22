import 'package:get/get.dart';

import '../modules/add_post/bindings/add_post_binding.dart';
import '../modules/add_post/views/add_post_view.dart';
import '../modules/bottom_bar/views/bottom_bar_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/profile/bindings/profile_binding.dart';
import '../modules/profile/views/profile_view.dart';
import '../modules/promotion/bindings/promotion_binding.dart';
import '../modules/promotion/views/promotion_view.dart';
import '../modules/ranking/bindings/ranking_binding.dart';
import '../modules/ranking/views/ranking_view.dart';
import '../modules/sign_up/bindings/sign_up_binding.dart';
import '../modules/sign_up/views/sign_up_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SIGN_UP;

  static final routes = [
    GetPage(
      name: _Paths.LOGIN,
      page: () => LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: _Paths.SIGN_UP,
      page: () => SignUpView(),
      binding: SignUpBinding(),
    ),
    GetPage(
      name: _Paths.HOME,
      page: () => HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.BOTTOM_BAR,
      page: () => BottomBarView(),
      // binding: BottomBarBinding(),
    ),
    GetPage(
      name: _Paths.PROFILE,
      page: () => ProfileView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: _Paths.PROMOTION,
      page: () => PromotionView(),
      binding: PromotionBinding(),
    ),
    GetPage(
      name: _Paths.ADD_POST,
      page: () => AddPostView(),
      binding: AddPostBinding(),
    ),
    GetPage(
      name: _Paths.RANKING,
      page: () => RankingView(),
      binding: RankingBinding(),
    ),
  ];
}
