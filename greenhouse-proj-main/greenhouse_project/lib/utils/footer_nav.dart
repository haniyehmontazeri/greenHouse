/// Creates a footer navigation bar
library;

import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:greenhouse_project/pages/chats.dart";
import "package:greenhouse_project/pages/greenhouse.dart";
import "package:greenhouse_project/pages/home.dart";
import "package:greenhouse_project/pages/inventory.dart";
import "package:greenhouse_project/pages/management.dart";
import "package:greenhouse_project/pages/tasks.dart";
import "package:greenhouse_project/services/cubit/footer_nav_cubit.dart";

void navigateToPage(BuildContext context, int index, String userRole,
    UserCredential userCredential,
    {DocumentReference? userReference}) {
  switch (index) {
    case 0:
      userRole != "worker"
          ? Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) => ManagementPage(
                        userCredential: userCredential,
                      )),
              (route) => false)
          : Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) => TasksPage(
                        userCredential: userCredential,
                        userReference: userReference!,
                      )),
              (route) => false);
      break;
    case 1:
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => InventoryPage(
                    userCredential: userCredential,
                  )),
          (route) => false);
      break;
    case 2:
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => HomePage(
                    userCredential: userCredential,
                  )),
          (route) => false);
      break;
    case 3:
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => GreenhousePage(
                    userCredential: userCredential,
                  )),
          (route) => false);
      break;
    case 4:
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => ChatsPage(
                    userCredential: userCredential,
                  )),
          (route) => false);
      break;
  }
}

BottomNavigationBar createFooterNav(
    int selectedIndex, FooterNavCubit footerNavCubit, String userRole) {
  final footerNav = BottomNavigationBar(
    elevation: 120,
    backgroundColor: Colors.transparent,
    type: BottomNavigationBarType.fixed,
    selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
    items: [
      userRole != "worker"
          ? const BottomNavigationBarItem(
              icon: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.precision_manufacturing_rounded)),
              label: "Manage")
          : const BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.task_outlined),
              ),
              label: "Tasks"),
      const BottomNavigationBarItem(
          icon: Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(Icons.inventory),
          ),
          label: "Inventory"),
      const BottomNavigationBarItem(
          icon: Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(Icons.home),
          ),
          label: "Home"),
      BottomNavigationBarItem(
          icon: Padding(
            padding: EdgeInsets.all(8.0),
            child:
                Image.asset("lib/utils/Icons/Leaf.png", width: 24, height: 24),
          ),
          label: "Grow"),
      const BottomNavigationBarItem(
          icon: Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(Icons.chat),
          ),
          label: "Chat"),
    ],
    currentIndex: selectedIndex,
    selectedItemColor: Colors.white60,
    onTap: (index) =>
        {if (selectedIndex != index) footerNavCubit.updateSelectedIndex(index)},
  );
  return footerNav;
}
