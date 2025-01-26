/// Tasks page - CRUD for employee tasks
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_holo_date_picker/flutter_holo_date_picker.dart';
import 'package:greenhouse_project/firebase_options.dart';
import 'package:greenhouse_project/services/cubit/chats_cubit.dart';
import 'package:greenhouse_project/services/cubit/footer_nav_cubit.dart';
import 'package:greenhouse_project/services/cubit/home_cubit.dart';
import 'package:greenhouse_project/services/cubit/management_cubit.dart';
import 'package:greenhouse_project/services/cubit/task_cubit.dart';
import 'package:greenhouse_project/services/cubit/task_edit_cubit.dart';
import 'package:greenhouse_project/utils/buttons.dart';
import 'package:greenhouse_project/utils/dialogs.dart';
import 'package:greenhouse_project/utils/footer_nav.dart';
import 'package:greenhouse_project/utils/input.dart';
import 'package:greenhouse_project/utils/appbar.dart';
import 'package:greenhouse_project/utils/theme.dart';

const String webVapidKey =
    "BKWvS-G0BOBMCAmBJVz63de5kFb5R2-OVxrM_ulKgCoqQgVXSY8FqQp7QM5UoC5S9hKs5crmzhVJVyyi_sYDC9I";

class TasksPage extends StatelessWidget {
  final UserCredential userCredential; // user auth credentials
  final DocumentReference? userReference;

  const TasksPage({
    super.key,
    required this.userCredential,
    required this.userReference,
  });

  @override
  Widget build(BuildContext context) {
    // Provide Cubits for state management
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => FooterNavCubit(),
        ),
        BlocProvider(
          create: (context) => NotificationsCubit(userCredential),
        ),
        BlocProvider(
          create: (context) => UserInfoCubit(),
        ),
        BlocProvider(create: (context) => TaskCubit(userReference!)),
        BlocProvider(create: (context) => TaskEditCubit()),
        BlocProvider(create: (context) => TaskDropdownCubit(context)),
        BlocProvider(create: (context) => ManageEmployeesCubit(userCredential)),
        BlocProvider(create: (context) => ChatsCubit(userCredential)),
      ],
      child: _TasksPageContent(
        userCredential: userCredential,
        userReference: userReference,
      ),
    );
  }
}

class _TasksPageContent extends StatefulWidget {
  final UserCredential userCredential; // user auth credentials
  final DocumentReference? userReference;

  const _TasksPageContent(
      {required this.userCredential, required this.userReference});

  @override
  State<_TasksPageContent> createState() => _TasksPageState();
}

// Main page content
class _TasksPageState extends State<_TasksPageContent> {
  // User info local variables
  late String _userRole = "";
  late DocumentReference _userReference;

  // Custom theme
  final ThemeData customTheme = theme;

  // Text controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _duedateController = TextEditingController();

  // Index of footer nav selection
  final int _selectedIndex = 0;

  // Dispose (destructor)
  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _duedateController.dispose();
    super.dispose();
  }

  // InitState - get user info state to check authentication later
  @override
  void initState() {
    super.initState();
    _initializeUserInfo();
  }

  @override
  Widget build(BuildContext context) {
    // BlocListener for handling footer nav events
    return BlocListener<FooterNavCubit, int>(
      listener: (context, state) {
        navigateToPage(context, state, _userRole, widget.userCredential,
            userReference: _userReference);
      },
      // BlocBuilder for user info
      child: BlocBuilder<UserInfoCubit, HomeState>(
        builder: (context, state) {
          // Show "loading screen" if processing user info
          if (state is UserInfoLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          // Show content once user info is loaded
          else if (state is UserInfoLoaded) {
            // Assign user info to local variables
            _userRole = state.userRole;
            _userReference = state.userReference;

            // Function call to create tasks page
            return Theme(data: customTheme, child: _createTasksPage());
          } // Show error if there is an issues with user info
          else if (state is UserInfoError) {
            return Center(child: Text('Error: ${state.errorMessage}'));
          }
          // If somehow state doesn't match predefined states;
          // never happens; but, anything can happen
          else {
            return const Center(
              child: Text('Unexpected state'),
            );
          }
        },
      ),
    );
  }

  /// Create tasks page UI
  Widget _createTasksPage() {
    // Get instance of footer nav cubit from main context
    final FooterNavCubit footerNavCubit =
        BlocProvider.of<FooterNavCubit>(context);

    return Scaffold(
      // Appbar (header)
      appBar: _userRole == "worker"
          ? createMainAppBar(
              context, widget.userCredential, _userReference, "Tasks")
          : createAltAppbar(context, "Tasks"),
      // Tasks section
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: _userRole == "worker"
              ? BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.lightBlueAccent.shade100.withOpacity(0.6),
                      Colors.teal.shade100.withOpacity(0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  image: DecorationImage(
                    image: const AssetImage('lib/utils/Icons/leaf_pat.jpg'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.white.withOpacity(0.05),
                      BlendMode.dstATop,
                    ),
                  ),
                )
              : BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.lightBlueAccent.shade100.withOpacity(0.6),
                      Colors.teal.shade100.withOpacity(0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  image: DecorationImage(
                    image: const AssetImage('lib/utils/Icons/tasks.png'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.white.withOpacity(0.05),
                      BlendMode.dstATop,
                    ),
                  ),
                ),
          child: Column(
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width - 20,
              ),
              // BlocBuilder for tasks
              BlocBuilder<TaskCubit, TaskState>(
                builder: (context, state) {
                  // Show "loading screen" if processing tasks state
                  if (state is TaskLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  // Show tasks if tasks state is loaded
                  else if (state is TaskLoaded) {
                    List<TaskData> taskList = state.tasks; // tasks list

                    // Display nothing if no tasks
                    if (taskList.isEmpty) {
                      return const Center(child: Text("No Tasks..."));
                    }
                    // Display tasks
                    else {
                      BuildContext mainContext = context;
                      return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.5,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: taskList.length,
                                  itemBuilder: (context, index) {
                                    TaskData task =
                                        taskList[index]; // task info
                                    return Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(15.0),
                                      ),
                                      elevation: 4.0,
                                      margin:
                                          const EdgeInsets.only(bottom: 16.0),
                                      child: ListTile(
                                        leading: Container(
                                          padding: const EdgeInsets.all(8.0),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.green.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.task_outlined,
                                            color: Colors.grey[600]!,
                                            size: 30,
                                          ),
                                        ),
                                        title: Text(
                                          task.title,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18),
                                        ),
                                        subtitle: Text(task.dueDate.toString()),
                                        trailing: WhiteElevatedButton(
                                          text: 'Details',
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) {
                                                return TaskDetailsDialog(
                                                  task: task,
                                                  userRole: _userRole,
                                                  managerReference:
                                                      _userRole == "worker"
                                                          ? task.manager
                                                          : null,
                                                  editOrComplete: _userRole ==
                                                              "worker" ||
                                                          (task.status ==
                                                                  "waiting" &&
                                                              _userRole ==
                                                                  "manager")
                                                      ? completeTask
                                                      : showEditForm,
                                                  deleteOrContact:
                                                      _userRole == "worker"
                                                          ? contactManager
                                                          : showDeleteForm,
                                                  mainContext: mainContext,
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ));
                    }
                  }
                  // Show error message once an error occurs
                  else if (state is TaskError) {
                    return Center(child: Text(state.error.toString()));
                  }
                  // If the state is not any of the predefined states;
                  // never happens; but, anything can happen
                  else {
                    return const Center(child: Text('Unexpected State'));
                  }
                },
              ),
            ],
          ),
        ),
      ),

      // Footer nav bar
      bottomNavigationBar: _userRole == "worker"
          ? PreferredSize(
              preferredSize: const Size.fromHeight(50.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.shade700,
                      Colors.teal.shade400,
                      Colors.blue.shade300
                    ],
                    stops: const [0.2, 0.5, 0.9],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, 3), // changes position of shadow
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    topRight: Radius.circular(30.0),
                  ),
                  child: createFooterNav(
                    _selectedIndex,
                    footerNavCubit,
                    _userRole,
                  ),
                ),
              ),
            )
          : const SizedBox(),

      floatingActionButton: _userRole == "manager"
          ? GreenElevatedButton(
              text: "Add Task", onPressed: () => showAddDialog())
          : const SizedBox(),
    );
  }

  void showEditForm(TaskData task) {
    // Get instance of cubits from the main context
    TaskCubit taskCubit = context.read<TaskCubit>();
    TaskEditCubit taskEditCubit = context.read<TaskEditCubit>();
    TaskDropdownCubit taskDropdownCubit = context.read<TaskDropdownCubit>();
    ManageEmployeesCubit manageEmployeesCubit =
        context.read<ManageEmployeesCubit>();

    // Set initial values for text controllers
    _titleController.text = task.title;
    _descController.text = task.description;
    _duedateController.text = task.dueDate.toString();

    // List of dropdown items
    Map<String, dynamic> dropdownItems = {};
    showDialog(
      context: context,
      builder: (context) {
        return BlocBuilder<ManageEmployeesCubit, ManagementState>(
          bloc: manageEmployeesCubit,
          builder: (context, state) {
            if (state is ManageEmployeesLoaded) {
              // Populate dropdown items with employees
              for (var employee in state.employees) {
                dropdownItems.addEntries({
                  "${employee.name} ${employee.surname}": employee.reference
                }.entries);
              }
              return BlocBuilder<TaskEditCubit, List<dynamic>>(
                bloc: taskEditCubit,
                builder: (context, taskEditState) {
                  // Pass an employee reference to TaskEditCubit for dropdown init
                  if (taskEditState[3] == null) {
                    List<dynamic> newState = taskEditState;
                    newState[3] = dropdownItems.entries.first.value;
                    taskEditCubit.updateState(newState);
                  }

                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      side: const BorderSide(
                        color: Colors.transparent,
                        width: 2.0, // Add border color and width
                      ),
                    ),
                    title: const Text("Edit task"),
                    content: SingleChildScrollView(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 400),
                        width: MediaQuery.of(context).size.width * .6,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title input field
                            InputTextField(
                              controller: _titleController,
                              errorText: taskEditState[0]
                                  ? null
                                  : "Title should not be empty",
                              labelText: "Title",
                            ),
                            // Description input field
                            InputTextField(
                              controller: _descController,
                              errorText: taskEditState[1]
                                  ? null
                                  : "Description should not be empty",
                              labelText: "Description",
                            ),
                            // Dropdown for selecting employees
                            InputDropdown(
                              items: dropdownItems,
                              value: dropdownItems.entries
                                  .firstWhere(
                                      (element) =>
                                          element.value == widget.userReference,
                                      orElse: () => dropdownItems.entries.first)
                                  .value,
                              onChanged: taskDropdownCubit.updateDropdown,
                            ),
                            // DatePicker widget for selecting due date
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 10, 0, 5),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 25),
                                  child: DatePickerWidget(
                                    looping: false,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime(2040, 1, 1),
                                    initialDate: DateTime.now(),
                                    dateFormat: "dd-MMM-yyyy",
                                    locale: DatePicker.localeFromString('en'),
                                    onChange: (DateTime newDate, _) =>
                                        taskEditCubit.updateState([
                                      taskEditState[0],
                                      taskEditState[1],
                                      newDate,
                                      taskEditState[3]
                                    ]),
                                    pickerTheme: const DateTimePickerTheme(
                                      itemTextStyle: TextStyle(
                                          color: Colors.black, fontSize: 19),
                                      dividerColor: Colors.blue,
                                      backgroundColor: Colors.transparent,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Submit & Cancel buttons
                            Row(
                              children: [
                                Expanded(
                                  child: GreenElevatedButton(
                                    text: 'Submit',
                                    onPressed: () {
                                      // Validate input fields
                                      List<dynamic> validation = [
                                        true,
                                        true,
                                        taskEditState[2],
                                        taskEditState[3],
                                      ];
                                      if (_titleController.text.isEmpty) {
                                        validation[0] = false;
                                      }
                                      if (_descController.text.isEmpty) {
                                        validation[1] = false;
                                      }
                                      bool isValid =
                                          taskEditCubit.updateState(validation);
                                      if (isValid) {
                                        // Update task
                                        taskCubit.updateTask(
                                            task.taskReference,
                                            {
                                              "title": _titleController.text,
                                              "description":
                                                  _descController.text,
                                              "worker": taskEditState[3],
                                              "dueDate": Timestamp
                                                  .fromMillisecondsSinceEpoch(
                                                      taskEditState[2]
                                                          .millisecondsSinceEpoch)
                                            },
                                            _userReference);

                                        // Close dialogs
                                        Navigator.pop(context);
                                        Navigator.pop(context);
                                        // Show success message
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                                content: Text(
                                                    "Task edited successfully")));
                                      } else {}
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: WhiteElevatedButton(
                                    text: 'Cancel',
                                    onPressed: () {
                                      // Close dialogs and clear text controllers
                                      Navigator.pop(context);
                                      Navigator.pop(context);
                                      _titleController.clear();
                                      _descController.clear();
                                      _duedateController.clear();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            } else {
              return const CircularProgressIndicator();
            }
          },
        );
      },
    );
  }

  void showDeleteForm(TaskData task) {
    // Get instance of TaskCubit from the main context
    TaskCubit taskCubit = BlocProvider.of<TaskCubit>(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
            side: const BorderSide(
              color: Colors.transparent,
              width: 2.0, // Add border color and width
            ),
          ),
          title: const Text("Are you sure?"),
          content: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              width: MediaQuery.of(context).size.width * .6,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: RedElevatedButton(
                            text: "Yes",
                            onPressed: () {
                              // Remove task and close dialogs
                              taskCubit.removeTask(
                                  task.taskReference, _userReference);
                              Navigator.pop(context);
                              Navigator.pop(context);
                              // Show success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text("Task deleted successfully!")));
                            }),
                      ),
                      Expanded(
                        child: WhiteElevatedButton(
                            text: "No",
                            onPressed: () {
                              // Close dialog
                              Navigator.pop(context);
                            }),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void showAddDialog() async {
    // Get instance of cubits from the main context
    TaskCubit taskCubit = context.read<TaskCubit>();
    TaskEditCubit taskEditCubit = context.read<TaskEditCubit>();
    TaskDropdownCubit taskDropdownCubit = context.read<TaskDropdownCubit>();
    ManageEmployeesCubit manageEmployeesCubit =
        context.read<ManageEmployeesCubit>();

    // Dropdown items list
    Map<String, dynamic> dropdownItems = {};
    showDialog(
        context: context,
        builder: (context) {
          return BlocBuilder<ManageEmployeesCubit, ManagementState>(
              bloc: manageEmployeesCubit,
              builder: (context, state) {
                if (state is ManageEmployeesLoaded) {
                  for (var employee in state.employees) {
                    dropdownItems.addEntries({
                      "${employee.name} ${employee.surname}": employee.reference
                    }.entries);
                  }
                  return BlocBuilder<TaskEditCubit, List<dynamic>>(
                    bloc: taskEditCubit,
                    builder: (context, taskEditState) {
                      return AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          side: const BorderSide(
                            color: Colors.transparent,
                            width: 2.0, // Add border color and width
                          ),
                        ),
                        title: const Text("Add task"),
                        content: SingleChildScrollView(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 400),
                            width: MediaQuery.of(context).size.width * .6,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title input field
                                InputTextField(
                                  controller: _titleController,
                                  errorText: taskEditState[0]
                                      ? null
                                      : "Title should not be empty",
                                  labelText: "Title",
                                ),
                                // Description input field
                                InputTextField(
                                  controller: _descController,
                                  errorText: taskEditState[1]
                                      ? null
                                      : "Description should not be empty",
                                  labelText: "Description",
                                ),
                                // Dropdown for selecting employees
                                InputDropdown(
                                  items: dropdownItems,
                                  value: dropdownItems.entries
                                      .firstWhere(
                                          (element) =>
                                              element.value ==
                                              widget.userReference,
                                          orElse: () =>
                                              dropdownItems.entries.first)
                                      .value,
                                  onChanged: taskDropdownCubit.updateDropdown,
                                ),
                                // DatePicker widget for selecting due date
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 10, 0, 5),
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 25),
                                      child: DatePickerWidget(
                                        looping:
                                            false, // default is not looping
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime(2040, 1, 1),
                                        initialDate: DateTime.now(),
                                        dateFormat: "dd-MMM-yyyy",
                                        locale:
                                            DatePicker.localeFromString('en'),
                                        onChange: (DateTime newDate, _) =>
                                            taskEditCubit.updateState([
                                          taskEditState[0],
                                          taskEditState[1],
                                          newDate,
                                          taskEditState[3]
                                        ]),
                                        pickerTheme: const DateTimePickerTheme(
                                          itemTextStyle: TextStyle(
                                              color: Colors.black,
                                              fontSize: 19),
                                          dividerColor: Colors.blue,
                                          backgroundColor: Colors.transparent,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                //Submit & Cancel buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: GreenElevatedButton(
                                        text: 'Submit',
                                        onPressed: () {
                                          // Validate input fields
                                          List<dynamic> validation = [
                                            true,
                                            true,
                                            taskEditState[2],
                                            taskEditState[3],
                                          ];
                                          if (_titleController.text.isEmpty) {
                                            validation[0] = false;
                                          }
                                          if (_descController.text.isEmpty) {
                                            validation[1] = false;
                                          }
                                          bool isValid = taskEditCubit
                                              .updateState(validation);
                                          if (isValid) {
                                            // Add task
                                            taskCubit.addTask(
                                              _titleController.text,
                                              _descController.text,
                                              taskEditState[2],
                                              taskEditState[3],
                                            );
                                            // Close dialog
                                            Navigator.pop(context);
                                            // Show success message
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    "Task has been created!"),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                    Expanded(
                                      child: WhiteElevatedButton(
                                        text: 'Cancel',
                                        onPressed: () {
                                          // Close dialog and clear text controllers
                                          Navigator.pop(context);
                                          _titleController.clear();
                                          _descController.clear();
                                          _duedateController.clear();
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  return const CircularProgressIndicator();
                }
              });
        });
  }

  void completeTask(BuildContext context, DocumentReference taskReference) {
    context.read<TaskCubit>().completeTask(taskReference);
    // Close dialog
    Navigator.pop(context);
    // Show completion message
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: _userRole == "manager"
            ? const Text("Task completion approved!")
            : const Text(
                "Task completion request sent, wait for manager approval.")));
  }

  void contactManager(
      BuildContext context, DocumentReference managerReference) {
    context.read<ChatsCubit>().createChat(context, managerReference);
  }

  Future<void> _initializeUserInfo() async {
    try {
      if (DefaultFirebaseOptions.currentPlatform !=
          DefaultFirebaseOptions.android) {
        context.read<UserInfoCubit>().getUserInfo(widget.userCredential, null);
      } else {
        String? deviceFcmToken =
            await FirebaseMessaging.instance.getToken(vapidKey: webVapidKey);
        if (mounted) {
          context
              .read<UserInfoCubit>()
              .getUserInfo(widget.userCredential, deviceFcmToken);
        }
      }
    } catch (e) {
      print('Error getting FCM token: $e');
    }
  }
}
