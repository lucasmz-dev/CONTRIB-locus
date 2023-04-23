import 'package:basic_utils/basic_utils.dart';
import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/material.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/services/task_service.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/RelaySelectSheet.dart';
import 'package:locus/widgets/TimerWidget.dart';
import 'package:locus/widgets/TimerWidgetSheet.dart';
import 'package:provider/provider.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({Key? key}) : super(key: key);

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _frequencyController = TextEditingController();
  final TimerController _timersController = TimerController();
  final RelayController _relaysController = RelayController();
  final _formKey = GlobalKey<FormState>();
  String? errorMessage;

  TaskCreationProgress? _taskProgress;

  @override
  void initState() {
    super.initState();

    _timersController.addListener(() {
      setState(() {
        errorMessage = null;
      });
    });
    _relaysController.addListener(() {
      setState(() {
        errorMessage = null;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _frequencyController.dispose();
    _timersController.dispose();
    _relaysController.dispose();

    super.dispose();
  }

  void rebuild() {
    setState(() {});
  }

  Future<void> createTask(final BuildContext context) async {
    setState(() {
      _taskProgress = TaskCreationProgress.startsSoon;
    });

    final taskService = context.read<TaskService>();

    try {
      final task = await Task.create(
        _nameController.text,
        Duration(minutes: int.parse(_frequencyController.text)),
        _relaysController.relays,
        onProgress: (progress) {
          setState(() {
            _taskProgress = progress;
          });
        },
        timers: _timersController.timers,
      );

      if (!mounted) {
        return;
      }

      taskService.add(task);
      await taskService.save();
      task.startSchedule();

      // Calling this explicitly so the text is cleared when leaving the screen
      setState(() {
        _taskProgress = null;
      });

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
    } finally {
      setState(() {
        _taskProgress = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom != 0;

    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: Text("Create Task"),
        material: (_, __) => MaterialAppBarData(
          centerTitle: true,
        ),
      ),
      material: (_, __) => MaterialScaffoldData(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(MEDIUM_SPACE),
        child: Center(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      if (!isKeyboardVisible)
                        Column(
                          children: <Widget>[
                            const SizedBox(height: SMALL_SPACE),
                            Text(
                              "Define a name and a frequency for your task",
                              style: getSubTitleTextStyle(context),
                            ),
                            const SizedBox(height: SMALL_SPACE),
                            Text(
                              "Note that a frequency of less than 15 minutes will automatically be set to 15 minutes. This is not set by us, but by the operating system.",
                              style: getCaptionTextStyle(context),
                            ),
                          ],
                        ),
                      const SizedBox(height: LARGE_SPACE),
                      Column(
                        children: <Widget>[
                          PlatformTextFormField(
                            controller: _nameController,
                            enabled: _taskProgress == null,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please enter a name";
                              }

                              if (!StringUtils.isAscii(value)) {
                                return "Name contains invalid characters";
                              }

                              return null;
                            },
                            material: (_, __) => MaterialTextFormFieldData(
                              decoration: InputDecoration(
                                labelText: "Name",
                                prefixIcon: Icon(context.platformIcons.tag),
                              ),
                            ),
                            cupertino: (_, __) => CupertinoTextFormFieldData(
                              placeholder: "Name",
                              prefix: Icon(context.platformIcons.tag),
                            ),
                          ),
                          const SizedBox(height: MEDIUM_SPACE),
                          PlatformTextFormField(
                            controller: _frequencyController,
                            enabled: _taskProgress == null,
                            textInputAction: TextInputAction.done,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please enter a frequency";
                              }

                              if (!StringUtils.isDigit(value)) {
                                return "Frequency must be a number";
                              }

                              final frequency = int.parse(value);

                              if (frequency < 1) {
                                return "Frequency must be greater than 0";
                              }

                              return null;
                            },
                            material: (_, __) => MaterialTextFormFieldData(
                              decoration: InputDecoration(
                                prefixIcon: Icon(context.platformIcons.time),
                                labelText: "Frequency",
                                prefixText: "Every",
                                suffix: Text("Minutes"),
                              ),
                            ),
                            cupertino: (_, __) => CupertinoTextFormFieldData(
                              placeholder: "Frequency",
                            ),
                          ),
                          const SizedBox(height: MEDIUM_SPACE),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              PlatformElevatedButton(
                                material: (_, __) => MaterialElevatedButtonData(
                                  icon: Icon(Icons.dns_rounded),
                                ),
                                onPressed: _taskProgress != null
                                    ? null
                                    : () {
                                        showPlatformModalSheet(
                                          context: context,
                                          material: MaterialModalSheetData(
                                            backgroundColor: Colors.transparent,
                                            isScrollControlled: true,
                                            isDismissible: true,
                                          ),
                                          builder: (_) => RelaySelectSheet(
                                            controller: _relaysController,
                                          ),
                                        );
                                      },
                                child: Text(
                                  _relaysController.relays.isEmpty
                                      ? "Select Relays"
                                      : "Selected ${_relaysController.relays.length} Relay${_relaysController.relays.length == 1 ? "" : "s"}",
                                ),
                              ),
                              PlatformElevatedButton(
                                material: (_, __) => MaterialElevatedButtonData(
                                  icon: const Icon(Icons.timer_rounded),
                                ),
                                onPressed: _taskProgress != null
                                    ? null
                                    : () async {
                                        await showPlatformModalSheet(
                                          context: context,
                                          material: MaterialModalSheetData(
                                            backgroundColor: Colors.transparent,
                                            isScrollControlled: true,
                                            isDismissible: true,
                                          ),
                                          builder: (_) => TimerWidgetSheet(
                                            controller: _timersController,
                                          ),
                                        );
                                      },
                                child: Text(
                                  _timersController.timers.isEmpty
                                      ? "Select Timers"
                                      : "Selected ${_timersController.timers.length} Timer${_timersController.timers.length == 1 ? "" : "s"}",
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (errorMessage != null) ...[
                  Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: getBodyTextTextStyle(context).copyWith(
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: MEDIUM_SPACE),
                ],
                if (_taskProgress != null) ...[
                  Center(
                    child: PlatformCircularProgressIndicator(),
                  ),
                  Text(
                    (() {
                      switch (_taskProgress) {
                        case TaskCreationProgress.startsSoon:
                          return "Task generation started...";
                        case TaskCreationProgress.creatingViewKeys:
                          return "Creating view keys...";
                        case TaskCreationProgress.creatingSignKeys:
                          return "Creating sign keys...";
                        case TaskCreationProgress.creatingTask:
                          return "Creating task...";
                        default:
                          return "";
                      }
                    })(),
                    textAlign: TextAlign.center,
                    style: getCaptionTextStyle(context),
                  ),
                ],
                PlatformElevatedButton(
                  padding: const EdgeInsets.all(MEDIUM_SPACE),
                  onPressed: _taskProgress != null
                      ? null
                      : () {
                          if (!_formKey.currentState!.validate()) {
                            return;
                          }

                          if (_relaysController.relays.isEmpty) {
                            setState(() {
                              errorMessage = "Please select at least one relay";
                            });
                            return;
                          }

                          createTask(context);
                        },
                  child: Text(
                    "Create",
                    style: TextStyle(
                      fontSize: getActionButtonSize(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
