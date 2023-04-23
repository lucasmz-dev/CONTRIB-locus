import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../constants/spacing.dart';
import '../../utils/theme.dart';

class ImportSuccess extends StatefulWidget {
  final void Function() onClose;

  const ImportSuccess({
    required this.onClose,
    Key? key,
  }) : super(key: key);

  @override
  State<ImportSuccess> createState() => _ImportSuccessState();
}

class _ImportSuccessState extends State<ImportSuccess> with TickerProviderStateMixin {
  late final AnimationController _lottieController;

  @override
  void initState() {
    super.initState();

    _lottieController = AnimationController(vsync: this)
      ..addStatusListener((status) async {
        if (status == AnimationStatus.completed) {
          await Future.delayed(const Duration(seconds: 3));

          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      });
  }

  @override
  void dispose() {
    _lottieController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Lottie.asset(
          "assets/lotties/success.json",
          frameRate: FrameRate.max,
          controller: _lottieController,
          onLoaded: (composition) {
            _lottieController
              ..duration = composition.duration
              ..forward();
          },
        ),
        const SizedBox(height: MEDIUM_SPACE),
        Text(
          "Task imported successfully!",
          textAlign: TextAlign.center,
          style: getSubTitleTextStyle(context),
        ),
        const SizedBox(height: MEDIUM_SPACE),
        PlatformElevatedButton(
          padding: const EdgeInsets.all(MEDIUM_SPACE),
          onPressed: widget.onClose,
          material: (_, __) => MaterialElevatedButtonData(
            icon: const Icon(Icons.check_rounded),
          ),
          child: const Text("Done"),
        ),
      ],
    );
  }
}