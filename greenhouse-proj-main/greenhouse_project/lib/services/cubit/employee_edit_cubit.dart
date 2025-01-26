import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class EmployeeDropdownCubit extends Cubit<String> {
  bool _isActive = true;
  final BuildContext context;
  EmployeeDropdownCubit(this.context) : super("worker");

  updateDropdown(String value) {
    if (!_isActive) return;
    emit(value);
    List<dynamic> validation = context.read<EmployeeEditCubit>().state;
    validation[1] = value;
    context.read<EmployeeEditCubit>().updateState(validation);
  }

  @override
  Future<void> close() {
    _isActive = false;
    return super.close();
  }
}

class EmployeeEditCubit extends Cubit<List<dynamic>> {
  bool _isActive = true;
  final BuildContext context;
  EmployeeEditCubit(this.context) : super([true, "worker"]);

  bool updateState(List<dynamic> validation) {
    if (!_isActive) return false;

    emit([...validation]);
    if (validation.contains(null) || validation.contains(false)) {
      return false;
    } else {
      return true;
    }
  }
  String updateDropdown(String value) {
    if (!_isActive) return "worker";
    bool valid = this.state[0];
    List<dynamic> validation = [valid, value];
    this.updateState(validation);
    return value;
  }

  @override
  Future<void> close() {
    _isActive = false;
    return super.close();
  }
}
