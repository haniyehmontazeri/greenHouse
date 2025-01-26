/// Employees page - CRUD for employee accounts
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:greenhouse_project/firebase_options.dart';
import 'package:greenhouse_project/pages/profile.dart';
import 'package:greenhouse_project/pages/tasks.dart';
import 'package:greenhouse_project/services/cubit/footer_nav_cubit.dart';
import 'package:greenhouse_project/services/cubit/home_cubit.dart';
import 'package:greenhouse_project/services/cubit/management_cubit.dart';
import 'package:greenhouse_project/services/cubit/employee_edit_cubit.dart';
import 'package:greenhouse_project/utils/appbar.dart';
import 'package:greenhouse_project/utils/buttons.dart';
import 'package:greenhouse_project/utils/dialogs.dart';
import 'package:greenhouse_project/utils/input.dart';
import 'package:greenhouse_project/utils/theme.dart';

const String webVapidKey =
    "BKWvS-G0BOBMCAmBJVz63de5kFb5R2-OVxrM_ulKgCoqQgVXSY8FqQp7QM5UoC5S9hKs5crmzhVJVyyi_sYDC9I";

class EmployeesPage extends StatelessWidget {
  final UserCredential userCredential; // User auth credentials

  const EmployeesPage({super.key, required this.userCredential});

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
        BlocProvider(create: (context) => ManageEmployeesCubit(userCredential)),
        BlocProvider(create: (context) => EmployeeEditCubit(context)),
        BlocProvider(create: (context) => EmployeeDropdownCubit(context)),
      ],
      child: _EmployeesPageContent(userCredential: userCredential),
    );
  }
}

class _EmployeesPageContent extends StatefulWidget {
  final UserCredential userCredential; // User auth credentials

  const _EmployeesPageContent({required this.userCredential});

  @override
  State<_EmployeesPageContent> createState() => _EmployeesPageState();
}

// Main page content
class _EmployeesPageState extends State<_EmployeesPageContent> {
  late DocumentReference _userReference;
  late String _userRole;

  // Custom theme
  final ThemeData customTheme = theme;

  // Text Controllers
  final TextEditingController _emailController = TextEditingController();

  // Dispose (destructor)
  @override
  void dispose() {
    _emailController.dispose();
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
    return BlocBuilder<UserInfoCubit, HomeState>(
      builder: (context, state) {
        // Show "loading screen" if processing user info state
        if (state is UserInfoLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        // Show content once user info is loaded
        else if (state is UserInfoLoaded) {
          // Function call to create employees page
          _userReference = state.userReference;
          _userRole = state.userRole;

          return Theme(data: customTheme, child: _createEmployeesPage());
        } else {
          return const Center(
            child: Text('Unexpected state'),
          );
        }
      },
    );
  }

  // Function to create employees page
  Widget _createEmployeesPage() {
    final ManageEmployeesCubit manageEmployeesCubit =
        BlocProvider.of<ManageEmployeesCubit>(context);
    final EmployeeEditCubit employeeEditCubit =
        BlocProvider.of<EmployeeEditCubit>(context);

    return Scaffold(
      appBar: createAltAppbar(context, "Employees"),
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.lightBlueAccent.shade100.withOpacity(0.6),
              Colors.teal.shade100.withOpacity(0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          image: DecorationImage(
            image: const AssetImage('lib/utils/Icons/worker.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.white.withOpacity(0.05),
              BlendMode.dstATop,
            ),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 40.0),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 20,
                ),
              ),
              // BlocBuilder for manageEmployees state
              BlocBuilder<ManageEmployeesCubit, ManagementState>(
                builder: (context, state) {
                  // Show "loading screen" if processing manageEmployees state
                  if (state is ManageEmployeesLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  // Show employees if manageEmployees state is loaded
                  else if (state is ManageEmployeesLoaded) {
                    List<EmployeeData> employeeList =
                        state.employees; // Employees list

                    // Display nothing if no employees
                    if (employeeList.isEmpty) {
                      return const Center(child: Text("No Employees..."));
                    }
                    // Display employees
                    else {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.7,
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: employeeList.length,
                                itemBuilder: (context, index) {
                                  EmployeeData employee =
                                      employeeList[index]; // Employee info
                                  return Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15.0),
                                    ),
                                    elevation: 4.0,
                                    margin: const EdgeInsets.only(bottom: 16.0),
                                    child: ListTile(
                                      leading: Container(
                                        padding: const EdgeInsets.all(8.0),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.account_box_outlined,
                                          color: Colors.grey[600]!,
                                          size: 30,
                                        ),
                                      ),
                                      title: Text(
                                        employee.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18),
                                      ),
                                      subtitle: Text(employee.enabled
                                          ? "Active"
                                          : "Inactive"),
                                      trailing: WhiteElevatedButton(
                                        text: 'Details',
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) {
                                              return EmployeeDetailsDialog(
                                                userRole: _userRole,
                                                employee: employee,
                                                tasksFunction: tasksFunction,
                                                toggleAccount: toggleAccount,
                                                profileFunction:
                                                    profileFunction,
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
                        ),
                      );
                    }
                  }
                  // Show error message once an error occurs
                  else if (state is ManageEmployeesError) {
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
      floatingActionButton: _userRole == "admin"
          ? GreenElevatedButton(
              text: 'Add Employee',
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (context) {
                      return BlocBuilder<EmployeeEditCubit, List<dynamic>>(
                        bloc: employeeEditCubit,
                        builder: (context, state) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              side: const BorderSide(
                                  color: Colors.transparent,
                                  width: 2.0), // Add border color and width
                            ),
                            title: const Text("Add employee"),
                            content: SingleChildScrollView(
                              child: Container(
                                constraints:
                                    const BoxConstraints(maxWidth: 400),
                                width: MediaQuery.of(context).size.width * .6,
                                child: Column(
                                  mainAxisSize: MainAxisSize
                                      .min, // Set column to minimum size
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  // Textfields
                                  children: [
                                    InputTextField(
                                        controller: _emailController,
                                        errorText: state[0]
                                            ? null
                                            : "Email cannot be empty!",
                                        labelText: "email"),

                                    SizedBox(
                                        width: double.maxFinite,
                                        child: InputDropdown(
                                          items: const {
                                            "worker": "worker",
                                            "manager": "manager"
                                          },
                                          value: state[1] != ''
                                              ? state[1]
                                              : "worker",
                                          onChanged:
                                              employeeEditCubit.updateDropdown,
                                        )),
                                    // Submit or Cancel
                                    Row(
                                      children: [
                                        Expanded(
                                          child: GreenElevatedButton(
                                              text: 'Submit',
                                              onPressed: () async {
                                                if (!_emailController.text
                                                    .contains(
                                                        RegExp(r'.+@.+\..+'))) {
                                                  employeeEditCubit.updateState(
                                                      [false, state[1]]);
                                                  return;
                                                }
                                                await manageEmployeesCubit
                                                    .createEmployee(
                                                        _emailController.text,
                                                        state[1],
                                                        _userReference);
                                                Navigator.pop(context);
                                                _emailController.clear();
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(const SnackBar(
                                                        content: Text(
                                                            "User account created successfully! Instructions have been sent via email.")));
                                              }),
                                        ),
                                        Expanded(
                                          child: WhiteElevatedButton(
                                              text: 'Cancel',
                                              onPressed: () {
                                                Navigator.pop(context);
                                                _emailController.clear();
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
                    });
              })
          : null,
    );
  }

  // Function to navigate to tasks page
  void tasksFunction(EmployeeData employee) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => TasksPage(
                  userCredential: widget.userCredential,
                  userReference: employee.reference,
                )));
  }

  // Function to toggle employee account status
  void toggleAccount(EmployeeData employee) {
    ManageEmployeesCubit manageEmployeesCubit =
        context.read<ManageEmployeesCubit>();
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
                side: BorderSide(
                    color: Colors.transparent,
                    width: 2.0), // Add border color and width
              ),
              title: const Text("Are you sure"),
              content: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                width: MediaQuery.of(context).size.width * .6,
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Set column to minimum size
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Row(
                        children: [
                          Expanded(
                            child: GreenElevatedButton(
                                text: "Confirm",
                                onPressed: () {
                                  if (employee.enabled) {
                                    manageEmployeesCubit
                                        .disableEmployee(
                                            employee, _userReference)
                                        .then((_) {
                                      Navigator.pop(context);
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text(
                                                  "Account disabled successfully!")));
                                    });
                                  } else {
                                    manageEmployeesCubit
                                        .enableEmployee(
                                            employee, _userReference)
                                        .then((_) {
                                      Navigator.pop(context);
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text(
                                                  "Account enabled successfully!")));
                                    });
                                  }
                                }),
                          ),
                          Expanded(
                            child: WhiteElevatedButton(
                                text: "Go Back",
                                onPressed: () => Navigator.pop(context)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ));
        });
  }

  // Function to navigate to profile page
  void profileFunction(EmployeeData employee) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ProfilePage(
                userCredential: widget.userCredential,
                userReference: employee.reference)));
  }

  // Initialize user info
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
