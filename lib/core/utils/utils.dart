import 'package:easy_url_launcher/easy_url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

void fToast(BuildContext context, {required String message, String? decription}) {
  toastification.show(
      context: context,
      title: Text(message),
      description:(decription!=null)? Text(decription):null,
      autoCloseDuration: const Duration(seconds: 3),
      alignment: Alignment.bottomCenter,
      type: ToastificationType.warning,
      style: ToastificationStyle.fillColored);
}

void launchURL(String url) async {
  await EasyLauncher.url(url: url, mode: Mode.platformDefault);
}
