import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/material.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/screens/import_task_sheet_widgets/ImportSelection.dart';
import 'package:locus/screens/import_task_sheet_widgets/ImportSuccess.dart';
import 'package:locus/screens/import_task_sheet_widgets/NameForm.dart';
import 'package:locus/screens/import_task_sheet_widgets/URLForm.dart';
import 'package:locus/screens/import_task_sheet_widgets/ViewImportOverview.dart';
import 'package:locus/services/view_service.dart';
import 'package:locus/utils/theme.dart';
import 'package:provider/provider.dart';

import '../widgets/ModalSheet.dart';

enum ImportScreen {
  ask,
  url,
  name,
  present,
  error,
  done,
}

class ImportTaskSheet extends StatefulWidget {
  const ImportTaskSheet({Key? key}) : super(key: key);

  @override
  State<ImportTaskSheet> createState() => _ImportTaskSheetState();
}

class _ImportTaskSheetState extends State<ImportTaskSheet> with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  ImportScreen _screen = ImportScreen.ask;
  String? errorMessage;
  TaskView? _taskView;

  void reset() {
    setState(() {
      _screen = ImportScreen.ask;
      errorMessage = null;
      _taskView = null;
    });
  }

  Future<void> importView() async {
    final viewService = context.read<ViewService>();

    viewService.add(_taskView!);
    await viewService.save();

    setState(() {
      _screen = ImportScreen.done;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ModalSheet(
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              children: <Widget>[
                Text(
                  "Import a task",
                  style: getSubTitleTextStyle(context),
                ),
                const SizedBox(height: LARGE_SPACE),
                if (_screen == ImportScreen.ask)
                  ImportSelection(
                    onGoToURL: () => setState(() {
                      _screen = ImportScreen.url;
                    }),
                    onTaskImported: (taskView) {
                      setState(() {
                        _taskView = taskView;
                        _screen = ImportScreen.name;
                      });
                    },
                    onTaskError: (message) {
                      setState(() {
                        errorMessage = message;
                        _screen = ImportScreen.error;
                      });
                    },
                  )
                else if (_screen == ImportScreen.url)
                  URLForm(
                    onSubmitted: (taskView) {
                      setState(() {
                        _taskView = taskView;
                        _screen = ImportScreen.name;
                      });
                    },
                    onTaskError: (message) {
                      setState(() {
                        errorMessage = message;
                        _screen = ImportScreen.error;
                      });
                    },
                  )
                else if (_screen == ImportScreen.name)
                  NameForm(
                    controller: _nameController,
                    onSubmitted: () {
                      _taskView!.update(name: _nameController.text);
                      setState(() {
                        _screen = ImportScreen.present;
                      });
                    },
                  )
                else if (_screen == ImportScreen.present)
                  ViewImportOverview(
                    view: _taskView!,
                    onGoToNameEdit: () => setState(() {
                      _screen = ImportScreen.name;
                    }),
                    onImport: importView,
                  )
                else if (_screen == ImportScreen.done)
                  ImportSuccess(
                    onClose: () => Navigator.of(context).pop(_taskView!),
                  )
                else if (_screen == ImportScreen.error)
                  Column(
                    children: <Widget>[
                      Icon(context.platformIcons.error, size: 64, color: Colors.red),
                      const SizedBox(height: MEDIUM_SPACE),
                      Text(
                        "An error occurred while importing the task",
                        style: getSubTitleTextStyle(context),
                      ),
                      const SizedBox(height: SMALL_SPACE),
                      Text(
                        errorMessage!,
                        style: getBodyTextTextStyle(context).copyWith(color: Colors.red),
                      ),
                      const SizedBox(height: LARGE_SPACE),
                      PlatformElevatedButton(
                        padding: const EdgeInsets.all(MEDIUM_SPACE),
                        onPressed: reset,
                        material: (_, __) => MaterialElevatedButtonData(
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        child: const Text("Go back"),
                      ),
                    ],
                  ),
                const SizedBox(height: LARGE_SPACE),
              ],
            ),
          ),
        ),
      ],
    );
  }
}