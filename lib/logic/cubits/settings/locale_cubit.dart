import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../infrastructure/app_prefs.dart';

class LocaleCubit extends Cubit<Locale> {
  static const supported = [Locale('ar'), Locale('fr'), Locale('en')];

  final AppPrefs prefs;

  LocaleCubit(this.prefs, {Locale? deviceLocale})
      : super(_initial(prefs.language, deviceLocale));

  static Locale _initial(String? saved, Locale? device) {
    final code = saved ?? device?.languageCode;
    return supported.firstWhere((l) => l.languageCode == code, orElse: () => const Locale('en'));
  }

  Future<void> setLocale(Locale locale) async {
    emit(locale);
    await prefs.setLanguage(locale.languageCode);
  }
}
