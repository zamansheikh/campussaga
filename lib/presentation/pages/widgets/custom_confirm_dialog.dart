import 'package:flutter/material.dart';

class CustomConfirmDialog {
  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    required String message,
    String? imagePath,
    required String confirmButtonText,
    required String cancelButtonText,
    required String dismissButtonText,
    required VoidCallback onTapConfirm,
    required VoidCallback onTapCancel,
    required VoidCallback onTapDismiss,
    required PanaraDialogType panaraDialogType,
    Color? color,
    Color? textColor,
    Color? buttonTextColor,
    EdgeInsets? margin,
    EdgeInsets? padding,
    bool barrierDismissible = true,
    bool noImage = false,
  }) =>
      showDialog<T>(
        barrierDismissible: barrierDismissible,
        context: context,
        builder: (context) => PanaraConfirmDialogWidget(
          noImage: noImage,
          title: title,
          message: message,
          confirmButtonText: confirmButtonText,
          cancelButtonText: cancelButtonText,
          dismissButtonText: dismissButtonText,
          onTapConfirm: onTapConfirm,
          onTapCancel: onTapCancel,
          onTapDismiss: onTapDismiss,
          panaraDialogType: panaraDialogType,
          color: color,
          textColor: textColor,
          buttonTextColor: buttonTextColor,
          imagePath: imagePath,
          margin: margin,
          padding: padding,
        ),
      );
}

enum PanaraDialogType { success, normal, warning, error, custom }

/// All the Colors used in the Dialog themes
class PanaraColors {
  /// <h3>Hex Code: #61D800</h3>
  static Color success = const Color(0xFF61D800);

  /// <h3>Hex Code: #179DFF</h3>
  static Color normal = const Color(0xFF179DFF);

  /// <h3>Hex Code: #FF8B17</h3>
  static Color warning = const Color(0xFFFF8B17);

  /// <h3>Hex Code: #FF4D17</h3>
  static Color error = const Color(0xFFFF4D17);

  /// <h3>Hex Code: #707070</h3>
  static Color defaultTextColor = const Color(0xFF707070);
}

///
/// PanaraConfirmDialogWidget, now includes an additional "Dismiss" button.
///
class PanaraConfirmDialogWidget extends StatelessWidget {
  final String? title;
  final String message;
  final String? imagePath;
  final String confirmButtonText;
  final String cancelButtonText;
  final String dismissButtonText;
  final VoidCallback onTapConfirm;
  final VoidCallback onTapCancel;
  final VoidCallback onTapDismiss;
  final PanaraDialogType panaraDialogType;
  final Color? color;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? buttonTextColor;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  /// If you don't want any icon or image, you toggle it to true.
  final bool noImage;

  const PanaraConfirmDialogWidget({
    Key? key,
    this.title,
    required this.message,
    required this.confirmButtonText,
    required this.cancelButtonText,
    required this.dismissButtonText,
    required this.onTapConfirm,
    required this.onTapCancel,
    required this.onTapDismiss,
    required this.panaraDialogType,
    this.color,
    this.backgroundColor,
    this.textColor = const Color(0xFF707070),
    this.buttonTextColor = Colors.white,
    this.imagePath,
    this.padding = const EdgeInsets.all(24),
    this.margin = const EdgeInsets.all(24),
    required this.noImage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Align(
      alignment: Alignment.center,
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 340,
          ),
          margin: margin ?? const EdgeInsets.all(24),
          padding: padding ?? const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: backgroundColor ?? theme.dialogBackgroundColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (!noImage)
                Image.asset(
                  imagePath ?? 'assets/confirm.png',
                  package: imagePath != null ? null : 'panara_dialogs',
                  width: 84,
                  height: 84,
                  color: imagePath != null
                      ? null
                      : (panaraDialogType == PanaraDialogType.normal
                          ? PanaraColors.normal
                          : panaraDialogType == PanaraDialogType.success
                              ? PanaraColors.success
                              : panaraDialogType == PanaraDialogType.warning
                                  ? PanaraColors.warning
                                  : panaraDialogType == PanaraDialogType.error
                                      ? PanaraColors.error
                                      : color),
                ),
              if (!noImage)
                const SizedBox(
                  height: 24,
                ),
              if (title != null)
                Text(
                  title ?? "",
                  style: TextStyle(
                    fontSize: 24,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              if (title != null)
                const SizedBox(
                  height: 5,
                ),
              Text(
                message,
                style: TextStyle(
                  color: textColor,
                  height: 1.5,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 30,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 1,
                    child: PanaraButton(
                      onTap: onTapCancel,
                      text: cancelButtonText,
                      bgColor: panaraDialogType == PanaraDialogType.normal
                          ? PanaraColors.normal
                          : panaraDialogType == PanaraDialogType.success
                              ? PanaraColors.success
                              : panaraDialogType == PanaraDialogType.warning
                                  ? PanaraColors.warning
                                  : panaraDialogType == PanaraDialogType.error
                                      ? PanaraColors.error
                                      : color ?? const Color(0xFF179DFF),
                      isOutlined: true,
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    flex: 2,
                    child: PanaraButton(
                      onTap: onTapDismiss,
                      text: dismissButtonText,
                      bgColor: Colors.grey,
                      isOutlined: true,
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    flex: 1,
                    child: PanaraButton(
                      buttonTextColor: buttonTextColor ?? Colors.white,
                      onTap: onTapConfirm,
                      text: confirmButtonText,
                      bgColor: panaraDialogType == PanaraDialogType.normal
                          ? PanaraColors.normal
                          : panaraDialogType == PanaraDialogType.success
                              ? PanaraColors.success
                              : panaraDialogType == PanaraDialogType.warning
                                  ? PanaraColors.warning
                                  : panaraDialogType == PanaraDialogType.error
                                      ? PanaraColors.error
                                      : color ?? const Color(0xFF179DFF),
                      isOutlined: false,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class PanaraButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final Color bgColor;
  final Color buttonTextColor;
  final bool isOutlined;

  const PanaraButton({
    Key? key,
    required this.text,
    this.onTap,
    required this.bgColor,
    required this.isOutlined,
    this.buttonTextColor = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: isOutlined ? theme.buttonTheme.colorScheme?.surface : bgColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            border: isOutlined ? Border.all(color: bgColor) : null,
            borderRadius: BorderRadius.circular(10),
            color: Colors.transparent,
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isOutlined ? bgColor : buttonTextColor,
            ),
          ),
        ),
      ),
    );
  }
}
