import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../infrastructure/app_prefs.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  final AppPrefs prefs;

  ThemeCubit(this.prefs)
      : super(ThemeMode.values.firstWhere(
          (mode) => mode.name == prefs.theme,
          orElse: () => ThemeMode.light,
        ));

  Future<void> setMode(ThemeMode mode) async {
    emit(mode);
    await prefs.setTheme(mode.name);
  }
}
