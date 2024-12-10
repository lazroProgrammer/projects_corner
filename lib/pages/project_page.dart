import 'package:drift/drift.dart' as p;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tasks/core/controllers/click_effect_controller.dart';
import 'package:tasks/core/controllers/segments_controller.dart';
import 'package:tasks/core/controllers/tasks_controller.dart';
import 'package:tasks/core/notifiers/darkmode_notifier.dart';
import 'package:tasks/database/database.dart';
import 'package:tasks/main.dart';
import 'package:tasks/pages/tasks_page.dart';
import 'package:tasks/theme/app_theme.dart';

const STATE_LIST = ["draft", "pending", "on going", "completed"];

class ProjectPage extends ConsumerWidget {
  ProjectPage({super.key});

  final List<String> names = [
    "Drift Database",
    "UI/UX Design",
    "State management using riverpod + Getx",
    "Write Tests",
    "Add some Polish",
    "Complete Deployement"
  ];
  final List<String> types = [
    "sqflite",
    "UI/UX",
    "UI",
    "automated testing",
    "animations, UI/UX",
    "deployment"
  ];

  final SegmentsController segmentsController =
      Get.find(tag: "project/segments");
  final ClickEffectController isClickedController =
      Get.find(tag: "segments_click_effect");
  final TasksController tasksController =
      Get.put(TasksController(-1), tag: "segments/tasks");
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = ref.watch(darkmodeNotifier);
    return Scaffold(
      appBar: AppBar(
        title: Text("ProjectID: ${segmentsController.projectID}"),
        actions: [
          IconButton(
            onPressed: () {
              ref.read(darkmodeNotifier.notifier).toggleDarkmode(dark);
            },
            icon: TweenAnimationBuilder(
                curve: Easing.legacyAccelerate,
                tween: Tween<double>(begin: 0, end: dark ? 0 : 2),
                duration: const Duration(milliseconds: 500),
                builder: (context, value, child) {
                  return Transform.rotate(
                      angle: value * 3.14, // Rotation animation
                      child: Opacity(
                        opacity: (1 - (value % 2)).abs(), // Fading effect
                        child: Icon(
                          dark ? Icons.dark_mode : Icons.light_mode,
                          size: 30,
                          color: dark ? Colors.blue[500] : Colors.yellow[700],
                        ),
                      ));
                }),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Obx(() {
          return GridView.builder(
            itemCount: segmentsController.segments.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, childAspectRatio: 0.9),
            itemBuilder: (context, index) {
              return Obx(
                () {
                  final isClicked = isClickedController.clickStates[index];
                  return Container(
                    padding: EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: AnimatedScale(
                      scale: isClicked ? 0.95 : 1.0,
                      duration: const Duration(milliseconds: 100),
                      child: Card(
                          elevation: (dark) ? 2 : 3,
                          shadowColor: (dark)
                              ? context.primaryColor
                              // : Theme.of(context).primaryColor,
                              : context.primaryColor,
                          color: (dark) ? context.primaryColor : Colors.white60,
                          child: InkWell(
                            onTapUp: (details) =>
                                isClickedController.buttonShrink(index),
                            onLongPress: () =>
                                isClickedController.buttonShrink(index),
                            onTapCancel: () =>
                                isClickedController.buttonEnlarge(index),
                            onTap: () {
                              isClickedController.buttonShrink(index);
                              isClickedController.buttonEnlarge(index);
                              tasksController.getTasksBySegmentID(
                                  segmentsController.segments[index].segmentID);
                              Get.to(
                                () => TasksPage(),
                                duration: Duration(milliseconds: 400),
                                transition: Transition.fade,
                              );
                            },
                            splashColor: (dark)
                                ? adjustBrightness(context.primaryColor,
                                    isDarkMode: dark, brightness: 0.6)
                                : adjustBrightness(context.primaryColor,
                                    isDarkMode: dark, brightness: 0.8),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              margin: EdgeInsets.fromLTRB(10, 10, 10, 6),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    names[index],
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(types[index])
                                ],
                              ),
                            ),
                          )),
                    ),
                  );
                },
              );
            },
          );
        }),
      ),
      floatingActionButton: Container(
        margin: EdgeInsets.all(8),
        child: FloatingActionButton(
          autofocus: true,
          shape: CircleBorder(side: BorderSide.none),
          onPressed: () {
            showSegmenttAddForum(context, ref, segmentsController);
          },
          backgroundColor:
              dark ? Color.fromARGB(255, 187, 187, 187) : Colors.grey[800],
          // Colors.grey[900],
          // foregroundColor: Colors.white,
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}

void showSegmenttAddForum(
    BuildContext context, WidgetRef ref, SegmentsController seg) {
  showDialog(
      context: context,
      builder: (context) {
        String selectedState = STATE_LIST[0];
        DateTime selectedTime = DateTime.now().copyWith(second: 0, minute: 0);
        DateTime deadline = DateTime.now().copyWith(second: 0, minute: 0);
        final formKey = GlobalKey<FormState>();
        final nameTEC = TextEditingController();
        final descriptTEC = TextEditingController();

        return AlertDialog(
          actions: [
            ElevatedButton(
                onPressed: () => Navigator.pop(context), child: Text("cancel")),
            ElevatedButton(
                onPressed: () {
                  bool isValid = formKey.currentState!.validate();
                  if (isValid && selectedTime.compareTo(deadline) < 0) {
                    final newSegment = SegmentsCompanion.insert(
                      projectID: seg.projectID.value,
                      name: nameTEC.text,
                      type: descriptTEC.text,
                      state: selectedState,
                      startDate: p.Value<DateTime?>(selectedTime),
                      completionDate: p.Value<DateTime?>(deadline),
                    );
                    seg.insertSegment(newSegment).then((_) {});
                    Navigator.pop(context);
                  } else if (selectedTime.compareTo(deadline) >= 0) {
                    Fluttertoast.showToast(
                        msg:
                            "you can't put the deadline before the project start");
                  }
                },
                child: Text("add"))
          ],
          content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return SizedBox(
                width: MediaQuery.of(context).size.width - 120,
                height: 450,
                child: Form(
                    key: formKey,
                    child: Column(
                      children: [
                        Text(
                          "Segment:",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                          child: TextFormField(
                            controller: nameTEC,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              hintText: "name",
                              prefixIcon: const Icon(Icons.abc_rounded),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim() == "") {
                                return "insert a name";
                              }
                              return null;
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                          child: TextFormField(
                            controller: descriptTEC,
                            maxLines: 1,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              hintText: "Type",
                              prefixIcon: const Icon(Icons.type_specimen),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim() == "") {
                                return "add a description";
                              }
                              return null;
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                          child: ListTile(
                            title: Text("State:"),
                            trailing: DropdownButton<String>(
                              value: selectedState,
                              onChanged: (String? newValue) {
                                setState(
                                  () {
                                    selectedState = newValue ?? STATE_LIST[0];
                                  },
                                );
                              },
                              items: STATE_LIST.map<DropdownMenuItem<String>>(
                                  (String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          child: Row(
                            children: [
                              Text("Start-Time: "),
                              Text(DateFormat('d/M/y').format(selectedTime)),
                              IconButton(
                                  onPressed: () async {
                                    final now = DateTime.now();
                                    final DateTime? picked =
                                        await showDatePicker(
                                            firstDate: now.copyWith(
                                                year: now.year - 1),
                                            lastDate: now.copyWith(
                                                year: now.year + 10),
                                            context: context,
                                            initialDate: selectedTime,
                                            initialEntryMode:
                                                DatePickerEntryMode.input);
                                    if (picked != null &&
                                        picked != selectedTime) {
                                      setState(() {
                                        selectedTime = picked;
                                      });
                                    }
                                  },
                                  icon: Icon(Icons.access_time))
                            ],
                          ),
                        ),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          child: Row(
                            children: [
                              Text("Deadline: "),
                              Text(DateFormat('d/M/y').format(deadline)),
                              IconButton(
                                  onPressed: () async {
                                    final now = DateTime.now();
                                    final DateTime? picked =
                                        await showDatePicker(
                                            firstDate: now.copyWith(
                                                year: now.year - 10),
                                            lastDate: now.copyWith(
                                                year: now.year + 10),
                                            context: context,
                                            initialDate: deadline,
                                            initialEntryMode:
                                                DatePickerEntryMode.input);
                                    if (picked != null && picked != deadline) {
                                      setState(() {
                                        deadline = picked;
                                      });
                                    }
                                  },
                                  icon: Icon(Icons.access_time))
                            ],
                          ),
                        ),
                      ],
                    )));
          }),
        );
      });
}