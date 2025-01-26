/// Cubit for plant status page
/// Handles plant status page state management
library;

import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter/foundation.dart";

part 'plants_state.dart';

class PlantStatusCubit extends Cubit<PlantStatusState> {
  CollectionReference plants = FirebaseFirestore.instance.collection("plants");

  final CollectionReference logs =
      FirebaseFirestore.instance.collection('logs');

  final DocumentReference userReference;

  bool _isActive = true;
  PlantStatusCubit(this.userReference) : super(PlantsLoading()) {
    _getPlants();
  }

  void _getPlants() async {
    if (!_isActive) return;
    //Get user Plants
    plants.orderBy('birthdate', descending: true).snapshots().listen(
        (snapshot) {
      final List<PlantData> plants =
          snapshot.docs.map((doc) => PlantData.fromFirestore(doc)).toList();
      emit(PlantsLoaded([...plants]));
    }, onError: (error) {
      emit(PlantsError(error.toString()));
    });
  }

  @override
  Future<void> close() {
    _isActive = false;
    return super.close();
  }

  Future<void> addPlant(
      Map<String, dynamic> data, DocumentReference userReference) async {
    if (!_isActive) return;
    try {
      DocumentReference externalId = await plants.add(data);

      DocumentSnapshot userSnapshot = await userReference.get();
      String name = userSnapshot.get("name");
      String surname = userSnapshot.get("surname");
      String stringDate = Timestamp.now().toDate().toString().substring(0, 10);
      String stringTime = Timestamp.now().toDate().toString().substring(11, 19);
      String plantType = data["type"];
      String plantSubtype = data["subtype"];

      await logs.add({
        "action": "create",
        "description":
            "\"$plantType, $plantSubtype\" plant added by \"$name $surname\" on $stringDate at $stringTime",
        "timestamp": Timestamp.now(),
        "type": "plant",
        "userId": userReference,
        "externalId": externalId,
      });
    } catch (error) {
      emit(PlantsError(error.toString()));
    }
  }

  Future<void> removePlant(
      DocumentReference item, DocumentReference userReference) async {
    if (!_isActive) return;
    emit(PlantsLoading());

    try {
      DocumentSnapshot snapshot = await item.get();
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

      await item.delete();

      DocumentSnapshot userSnapshot = await userReference.get();
      String name = userSnapshot.get("name");
      String surname = userSnapshot.get("surname");
      String stringDate = Timestamp.now().toDate().toString().substring(0, 10);
      String stringTime = Timestamp.now().toDate().toString().substring(11, 19);
      String plantType = data["type"];
      String plantSubtype = data["subtype"];

      await logs.add({
        "action": "Delete",
        "description":
            "\"$plantType, $plantSubtype\" plant deleted by \"$name $surname\" on $stringDate at $stringTime",
        "timestamp": Timestamp.now(),
        "type": "Plant",
        "userId": userReference,
        "externalId": item,
      });
    } catch (error, stack) {
      emit(PlantsError(stack.toString()));
    }
  }
}

class PlantData {
  final String type;
  final String subtype;
  final DateTime birthdate;
  final int boardNo;
  final DocumentReference plantReference;

  PlantData(
      {required this.type,
      required this.subtype,
      required this.birthdate,
      required this.boardNo,
      required this.plantReference});

  factory PlantData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return PlantData(
      birthdate: (data['birthdate'] as Timestamp).toDate(),
      subtype: data['subtype'],
      type: data['type'],
      boardNo: data['boardNo'],
      plantReference: doc.reference,
    );
  }
}

class ReadingsData {
  final Map<int, Map<String, dynamic>> boardReadings;

  ReadingsData({required this.boardReadings});

  factory ReadingsData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Initialize an empty map to store readings
    Map<int, Map<String, dynamic>> readingsMap = {};

    // Iterate over the keys of the data map
    data.forEach((key, value) {
      // Parse the key to an integer representing the board number
      int boardNo = int.tryParse(key) ?? 0;

      // Check if the value is a map
      if (value is Map<String, dynamic>) {
        // Add the board readings to the readings map
        readingsMap[boardNo] = value;
      }
    });

    // Return a new ReadingsData instance with the parsed readings map
    return ReadingsData(boardReadings: readingsMap);
  }
}
