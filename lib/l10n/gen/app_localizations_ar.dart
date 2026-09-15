// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'جرد';

  @override
  String get cancel => 'إلغاء';

  @override
  String get confirm => 'تأكيد';

  @override
  String get delete => 'حذف';

  @override
  String get save => 'حفظ';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get close => 'إغلاق';

  @override
  String get clear => 'مسح';

  @override
  String get later => 'لاحقًا';

  @override
  String get you => 'أنت';

  @override
  String get errorNetwork => 'تعذّر الوصول إلى الخادم. تحقّق من الاتصال.';

  @override
  String get errorInvalidCredentials =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة.';

  @override
  String errorDuplicateBarcode(String name) {
    return 'هذا الرمز الشريطي مستخدم بالفعل لـ $name.';
  }

  @override
  String get errorValidation => 'يرجى مراجعة الحقول المحدّدة.';

  @override
  String get errorNotFound => 'هذا العنصر لم يعد موجودًا.';

  @override
  String get errorCountInProgress =>
      'هناك جرد قيد التنفيذ. أنهِه قبل تسجيل الحركات.';

  @override
  String get errorPermissionDenied => 'صاحب المحل فقط يمكنه القيام بذلك.';

  @override
  String get errorServerNotConfigured =>
      'لا يوجد خادم مُعدّ لهذه النسخة. كل شيء يبقى على هذا الهاتف.';

  @override
  String errorServer(String message) {
    return 'رفض الخادم الطلب: $message';
  }

  @override
  String get errorUnknown => 'حدث خطأ ما. يرجى المحاولة مرة أخرى.';

  @override
  String get fieldRequired => 'هذا الحقل مطلوب.';

  @override
  String get fieldInvalidEmail => 'أدخل بريدًا إلكترونيًا صالحًا.';

  @override
  String fieldPasswordTooShort(int min) {
    return 'يجب أن تحتوي كلمة المرور على $min أحرف على الأقل.';
  }

  @override
  String get fieldInvalidNumber => 'أدخل رقمًا صالحًا.';

  @override
  String get fieldNegative => 'لا يمكن أن تكون القيمة سالبة.';

  @override
  String get fieldInvalidBarcode => 'الرمز الشريطي من 4 إلى 14 رقمًا.';

  @override
  String get fieldZeroQuantity => 'أدخل كمية غير الصفر.';

  @override
  String get fieldTooLong => 'النص طويل جدًا.';

  @override
  String get fieldDuplicate => 'مستخدم بالفعل.';

  @override
  String get loginTagline => 'احسب مخزونك،\nحتى بدون شبكة.';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get showPassword => 'إظهار كلمة المرور';

  @override
  String get hidePassword => 'إخفاء كلمة المرور';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get forgotPasswordHelp =>
      'اطلب من صاحب المحل إعادة تعيين كلمة المرور.';

  @override
  String get noAccount => 'ليس لديك حساب؟ اطلب من صاحب المحل إضافتك.';

  @override
  String demoAccounts(String email, String password) {
    return 'تجربة: $email / $password';
  }

  @override
  String get navProducts => 'المنتجات';

  @override
  String get navCount => 'الجرد';

  @override
  String get navAlerts => 'التنبيهات';

  @override
  String get navSync => 'المزامنة';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get productsTitle => 'المنتجات';

  @override
  String shopItems(String shop, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count منتج',
      many: '$count منتجًا',
      few: '$count منتجات',
      two: 'منتجان',
      one: 'منتج واحد',
      zero: 'لا منتجات',
    );
    return '$shop · $_temp0';
  }

  @override
  String get myShop => 'محلي';

  @override
  String get offlineBanner =>
      'أنت غير متصل. التغييرات محفوظة على هذا الهاتف وستُزامن لاحقًا.';

  @override
  String get searchHint => 'ابحث بالاسم أو الرمز الشريطي';

  @override
  String get filterAll => 'الكل';

  @override
  String get filterLow => 'مخزون منخفض';

  @override
  String get filterOut => 'نفد';

  @override
  String get noProductsFound => 'لم يتم العثور على منتجات.';

  @override
  String get emptyProductsTitle => 'لا توجد منتجات بعد';

  @override
  String get emptyProductsBody =>
      'امسح رمزًا شريطيًا أو اضغط + لإضافة أول منتج.';

  @override
  String get addProduct => 'إضافة منتج';

  @override
  String get scan => 'مسح';

  @override
  String badgeLow(int point) {
    return 'منخفض · اطلب عند $point';
  }

  @override
  String get outOfStock => 'نفد المخزون';

  @override
  String get lowStock => 'مخزون منخفض';

  @override
  String get inStock => 'متوفر';

  @override
  String get loadFailed => 'تعذّر تحميل منتجاتك.';

  @override
  String get productCreated => 'تمت إضافة المنتج.';

  @override
  String get productUpdated => 'تم تحديث المنتج.';

  @override
  String get productDeleted => 'تم حذف المنتج.';

  @override
  String get movementRecorded => 'تم تسجيل الحركة.';

  @override
  String get openMenu => 'فتح القائمة';

  @override
  String get today => 'اليوم';

  @override
  String get yesterday => 'أمس';

  @override
  String get todaySummary => 'ملخص اليوم';

  @override
  String get summaryReceived => 'المستلم';

  @override
  String get summarySold => 'المباع';

  @override
  String get summaryAdjusted => 'المعدّل';

  @override
  String summaryMovements(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count حركة اليوم',
      many: '$count حركة اليوم',
      few: '$count حركات اليوم',
      two: 'حركتان اليوم',
      one: 'حركة واحدة اليوم',
      zero: 'لا حركات اليوم بعد',
    );
    return '$_temp0';
  }

  @override
  String get edit => 'تعديل';

  @override
  String get more => 'المزيد';

  @override
  String get deleteProduct => 'حذف المنتج';

  @override
  String get deleteProductTitle => 'حذف المنتج؟';

  @override
  String deleteProductBody(String name) {
    return 'سيُزال $name من قائمة المنتجات.';
  }

  @override
  String get reorderWhen => 'اطلب عندما يصل إلى ';

  @override
  String get reasonReceived => 'استلام';

  @override
  String get reasonSold => 'بيع';

  @override
  String get reasonAdjust => 'تعديل';

  @override
  String get history => 'السجل';

  @override
  String get seeAll => 'عرض الكل';

  @override
  String get showLess => 'عرض أقل';

  @override
  String get noMovements => 'لا توجد حركات بعد.';

  @override
  String historyReceived(int amount) {
    return 'استلام $amount';
  }

  @override
  String historySold(int amount) {
    return 'بيع $amount';
  }

  @override
  String historyAdjusted(String amount) {
    return 'تعديل $amount';
  }

  @override
  String historyCounted(String amount) {
    return 'جرد $amount';
  }

  @override
  String get productGone => 'تم حذف هذا المنتج.';

  @override
  String get recordMovement => 'تسجيل حركة';

  @override
  String nowInStock(int stock, String unit) {
    return 'المخزون الحالي: $stock $unit';
  }

  @override
  String questionReceived(String unit) {
    return 'كم $unit وصل؟';
  }

  @override
  String questionSold(String unit) {
    return 'كم $unit بيع؟';
  }

  @override
  String questionAdjust(String unit) {
    return 'تعديل بكم $unit؟';
  }

  @override
  String get decrease => 'إنقاص';

  @override
  String get increase => 'زيادة';

  @override
  String get stockAfterSaving => 'المخزون بعد الحفظ';

  @override
  String get noteOptional => 'ملاحظة (اختيارية)';

  @override
  String get noteHintReceived => 'مثلًا: توصيل من المورّد';

  @override
  String get noteHintSold => 'مثلًا: بيع لزبون دائم';

  @override
  String get noteHintAdjust => 'مثلًا: كسر زجاجتين';

  @override
  String saveReceived(int amount) {
    return 'حفظ · استلام $amount';
  }

  @override
  String saveSold(int amount) {
    return 'حفظ · بيع $amount';
  }

  @override
  String saveAdjusted(String amount) {
    return 'حفظ · تعديل $amount';
  }

  @override
  String get savedLocallyHint =>
      'يُحفظ على هذا الهاتف فورًا، ويُزامن عند الاتصال.';

  @override
  String get editProduct => 'تعديل المنتج';

  @override
  String get addPhoto => 'إضافة صورة';

  @override
  String get cameraOrGallery => 'الكاميرا أو المعرض';

  @override
  String get changePhoto => 'تغيير الصورة';

  @override
  String get removePhoto => 'إزالة الصورة';

  @override
  String get takePhoto => 'التقاط صورة';

  @override
  String get chooseFromGallery => 'اختيار من المعرض';

  @override
  String get productName => 'الاسم';

  @override
  String get barcode => 'الرمز الشريطي';

  @override
  String get unit => 'الوحدة';

  @override
  String get reorderAt => 'اطلب عند';

  @override
  String get reorderHelp => 'ستتلقى تنبيهًا عندما ينخفض المخزون إلى هذا الرقم.';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get scanToFill => 'مسح الرمز الشريطي';

  @override
  String get suggestFromPhoto => 'اقتراح الاسم من الصورة';

  @override
  String get suggestionApplied => 'تم الملء من الملصق. تحقّق قبل الحفظ.';

  @override
  String get suggestionFailed => 'تعذّرت قراءة الملصق. اكتب الاسم.';

  @override
  String get scanBarcode => 'مسح الرمز الشريطي';

  @override
  String get pointCamera => 'وجّه الكاميرا نحو الرمز الشريطي';

  @override
  String get typeNumberInstead => 'اكتب الرقم بدلًا من ذلك';

  @override
  String get typeBarcodeTitle => 'اكتب الرمز الشريطي';

  @override
  String get find => 'بحث';

  @override
  String get flashOn => 'تشغيل الفلاش';

  @override
  String get flashOff => 'إطفاء الفلاش';

  @override
  String get found => 'تم العثور عليه';

  @override
  String get notFound => 'غير موجود';

  @override
  String get noProductWithBarcode => 'لا يوجد منتج بهذا الرمز الشريطي بعد.';

  @override
  String inStockCount(int stock, String unit) {
    return '$stock $unit في المخزون';
  }

  @override
  String get cameraPermissionDenied =>
      'الوصول إلى الكاميرا معطّل. فعّله من الإعدادات، أو اكتب الرقم.';

  @override
  String get openSettings => 'فتح الإعدادات';

  @override
  String get cameraUnavailable =>
      'لا توجد كاميرا هنا. اكتب الرقم بدلًا من ذلك.';

  @override
  String get stockCount => 'الجرد';

  @override
  String countedOf(int total) {
    return 'من $total تم عدّها';
  }

  @override
  String get justScanned => 'آخر مسح';

  @override
  String expectedQty(int count) {
    return 'المتوقع $count';
  }

  @override
  String get oneLess => 'واحد أقل';

  @override
  String get oneMore => 'واحد أكثر';

  @override
  String get differences => 'الفروقات';

  @override
  String get allCounted => 'كل ما عُدّ';

  @override
  String get noDifferences => 'لا فروقات حتى الآن.';

  @override
  String get nothingCounted => 'لم يُعدّ شيء بعد. امسح أول منتج على الرف.';

  @override
  String get finishCount => 'إنهاء الجرد';

  @override
  String get scanNext => 'مسح التالي';

  @override
  String expectedCounted(int expected, int counted) {
    return 'المتوقع $expected · المعدود $counted';
  }

  @override
  String get finishCountTitle => 'إنهاء الجرد؟';

  @override
  String get finishCountNoDiff => 'لا توجد فروقات. يبقى المخزون كما هو.';

  @override
  String finishCountBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count منتج',
      many: '$count منتجًا',
      few: '$count منتجات',
      two: 'منتجين',
      one: 'منتج واحد',
    );
    return 'سيتم تصحيح المخزون لـ $_temp0.';
  }

  @override
  String get commitCount => 'حفظ الجرد';

  @override
  String get keepCounting => 'متابعة العد';

  @override
  String get countSaved => 'تم حفظ الجرد.';

  @override
  String get leaveCountTitle => 'مغادرة الجرد؟';

  @override
  String get leaveCountBody =>
      'عدّك محفوظ على هذا الهاتف. تابعه لاحقًا أو تجاهله.';

  @override
  String get continueLater => 'المتابعة لاحقًا';

  @override
  String get discardCount => 'تجاهل';

  @override
  String unknownBarcode(String code) {
    return 'لا يوجد منتج بالرمز $code.';
  }

  @override
  String get everythingCounted => 'تم عدّ كل شيء.';

  @override
  String get countInProgressBanner =>
      'جرد قيد التنفيذ — الحركات متوقفة مؤقتًا.';

  @override
  String get resumeCount => 'متابعة';

  @override
  String get mostUrgentFirst => 'الأكثر إلحاحًا أولًا';

  @override
  String get allStockedUp => 'المخزون مكتمل';

  @override
  String itemsToRestock(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count منتج يحتاج إعادة تزويد',
      many: '$count منتجًا يحتاج إعادة تزويد',
      few: '$count منتجات تحتاج إعادة تزويد',
      two: 'منتجان يحتاجان إعادة تزويد',
      one: 'منتج واحد يحتاج إعادة تزويد',
    );
    return '$_temp0';
  }

  @override
  String get noRestockNeeded => 'لا توجد منتجات تحتاج إعادة تزويد.';

  @override
  String get belowReorderPoint => 'أقل من حد الطلب';

  @override
  String ofReorder(int point) {
    return 'من $point';
  }

  @override
  String get recordReceived => 'تسجيل استلام';

  @override
  String get reorderIdeas => 'اقتراحات الطلب';

  @override
  String get reorderIdeasFailed => 'تعذّر إعداد الاقتراحات الآن.';

  @override
  String get syncTitle => 'المزامنة';

  @override
  String get youreOffline => 'أنت غير متصل';

  @override
  String get youreOnline => 'أنت متصل';

  @override
  String get syncing => 'جارٍ المزامنة…';

  @override
  String get allSynced => 'تمت مزامنة كل شيء';

  @override
  String lastSynced(String time) {
    return 'آخر مزامنة $time';
  }

  @override
  String get neverSynced => 'لم تتم المزامنة بعد';

  @override
  String pendingOffline(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تغيير محفوظ على هذا الهاتف، وستُرفع تلقائيًا عند الاتصال.',
      many:
          '$count تغييرًا محفوظًا على هذا الهاتف، وستُرفع تلقائيًا عند الاتصال.',
      few:
          '$count تغييرات محفوظة على هذا الهاتف، وستُرفع تلقائيًا عند الاتصال.',
      two: 'تغييران محفوظان على هذا الهاتف، وسيُرفعان تلقائيًا عند الاتصال.',
      one: 'تغيير واحد محفوظ على هذا الهاتف، وسيُرفع تلقائيًا عند الاتصال.',
      zero: 'لا شيء في الانتظار. التغييرات الجديدة تُحفظ على هذا الهاتف.',
    );
    return '$_temp0';
  }

  @override
  String pendingOnline(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تغيير في انتظار الرفع.',
      many: '$count تغييرًا في انتظار الرفع.',
      few: '$count تغييرات في انتظار الرفع.',
      two: 'تغييران في انتظار الرفع.',
      one: 'تغيير واحد في انتظار الرفع.',
      zero: 'كل تغييراتك على الخادم.',
    );
    return '$_temp0';
  }

  @override
  String get trySyncNow => 'جرّب المزامنة الآن';

  @override
  String get syncNow => 'زامن الآن';

  @override
  String get syncFailed => 'لم تكتمل المزامنة. ستُعاد المحاولة تلقائيًا.';

  @override
  String get syncDone => 'اكتملت المزامنة.';

  @override
  String waitingToUpload(int count) {
    return 'في انتظار الرفع · $count';
  }

  @override
  String needsALook(int count) {
    return 'يحتاج مراجعة · $count';
  }

  @override
  String conflictTitle(String name) {
    return 'تم تغيير $name على هاتفين';
  }

  @override
  String conflictDetail(
    String kept,
    String keptBy,
    String keptAt,
    String lost,
    String lostBy,
    String lostAt,
  ) {
    return 'تم الإبقاء على «$kept» ($keptBy، $keptAt). واستُبدل «$lost» ($lostBy، $lostAt).';
  }

  @override
  String get dismiss => 'إخفاء';

  @override
  String pendingEdited(String name) {
    return 'تعديل · $name';
  }

  @override
  String pendingMovement(String action, String name) {
    return '$action · $name';
  }

  @override
  String get demoModeTitle => 'وضع التجربة';

  @override
  String get demoModeBody =>
      'هذه النسخة بدون خادم، لذا يبقى كل شيء على هذا الهاتف.';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get theme => 'المظهر';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get themeSystem => 'النظام';

  @override
  String get staffAccounts => 'حسابات الموظفين';

  @override
  String get roleOwner => 'المالك';

  @override
  String get roleStaff => 'موظف';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get signOutTitle => 'تسجيل الخروج؟';

  @override
  String get signOutBody =>
      'تُحذف البيانات من هذا الهاتف ليبدأ الشخص التالي من جديد.';

  @override
  String signOutPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تغيير لم تتم مزامنته وسيضيع.',
      many: '$count تغييرًا لم تتم مزامنته وسيضيع.',
      few: '$count تغييرات لم تتم مزامنتها وستضيع.',
      two: 'تغييران لم تتم مزامنتهما وسيضيعان.',
      one: 'تغيير واحد لم تتم مزامنته وسيضيع.',
    );
    return '$_temp0';
  }

  @override
  String appVersion(String version) {
    return 'جرد $version';
  }

  @override
  String get addStaff => 'إضافة موظف';

  @override
  String get staffName => 'الاسم';

  @override
  String get role => 'الدور';

  @override
  String get staffAdded => 'تم إنشاء الحساب.';

  @override
  String get staffRemoved => 'تمت إزالة الحساب.';

  @override
  String get removeStaffTitle => 'إزالة الحساب؟';

  @override
  String removeStaffBody(String name) {
    return 'لن يتمكن $name من تسجيل الدخول بعد الآن.';
  }

  @override
  String get remove => 'إزالة';

  @override
  String get ownerOnlyStaff => 'المالك فقط يمكنه إضافة الحسابات أو إزالتها.';

  @override
  String updateAvailable(String version) {
    return 'تحديث متوفر: $version';
  }

  @override
  String get updateRequired =>
      'هذه النسخة قديمة جدًا. حدّث التطبيق لمواصلة المزامنة.';

  @override
  String get updateNow => 'تحديث';
}
