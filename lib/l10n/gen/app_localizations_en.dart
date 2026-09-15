// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Jerd';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get retry => 'Try again';

  @override
  String get close => 'Close';

  @override
  String get clear => 'Clear';

  @override
  String get later => 'Later';

  @override
  String get you => 'You';

  @override
  String get errorNetwork => 'Can\'t reach the server. Check your connection.';

  @override
  String get errorInvalidCredentials => 'Wrong email or password.';

  @override
  String errorDuplicateBarcode(String name) {
    return 'This barcode already belongs to $name.';
  }

  @override
  String get errorValidation => 'Please check the highlighted fields.';

  @override
  String get errorNotFound => 'This item no longer exists.';

  @override
  String get errorCountInProgress =>
      'A stock count is in progress. Finish it before recording movements.';

  @override
  String get errorPermissionDenied => 'Only the shop owner can do this.';

  @override
  String get errorServerNotConfigured =>
      'No server is set up for this build. Everything stays on this phone.';

  @override
  String errorServer(String message) {
    return 'The server refused the request: $message';
  }

  @override
  String get errorUnknown => 'Something went wrong. Please try again.';

  @override
  String get fieldRequired => 'This field is required.';

  @override
  String get fieldInvalidEmail => 'Enter a valid email.';

  @override
  String fieldPasswordTooShort(int min) {
    return 'Password must contain at least $min characters.';
  }

  @override
  String get fieldInvalidNumber => 'Enter a valid number.';

  @override
  String get fieldNegative => 'This can\'t be negative.';

  @override
  String get fieldInvalidBarcode => 'A barcode is 4 to 14 digits.';

  @override
  String get fieldZeroQuantity => 'Enter a quantity other than zero.';

  @override
  String get fieldTooLong => 'This is too long.';

  @override
  String get fieldDuplicate => 'This is already in use.';

  @override
  String get loginTagline => 'Count your stock,\neven with no signal.';

  @override
  String get signIn => 'Sign in';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get forgotPasswordHelp =>
      'Ask your shop owner to reset your password.';

  @override
  String get noAccount => 'No account? Ask your shop owner to add you.';

  @override
  String demoAccounts(String email, String password) {
    return 'Demo: $email / $password';
  }

  @override
  String get navProducts => 'Products';

  @override
  String get navCount => 'Count';

  @override
  String get navAlerts => 'Alerts';

  @override
  String get navSync => 'Sync';

  @override
  String get navSettings => 'Settings';

  @override
  String get productsTitle => 'Products';

  @override
  String shopItems(String shop, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$shop · $_temp0';
  }

  @override
  String get myShop => 'My shop';

  @override
  String get offlineBanner =>
      'You\'re offline. Changes are saved on this phone and will sync later.';

  @override
  String get searchHint => 'Search name or barcode';

  @override
  String get filterAll => 'All';

  @override
  String get filterLow => 'Low stock';

  @override
  String get filterOut => 'Out';

  @override
  String get noProductsFound => 'No products found.';

  @override
  String get emptyProductsTitle => 'No products yet';

  @override
  String get emptyProductsBody =>
      'Scan a barcode or tap + to add your first product.';

  @override
  String get addProduct => 'Add product';

  @override
  String get scan => 'Scan';

  @override
  String badgeLow(int point) {
    return 'Low · reorder at $point';
  }

  @override
  String get outOfStock => 'Out of stock';

  @override
  String get lowStock => 'Low stock';

  @override
  String get inStock => 'In stock';

  @override
  String get loadFailed => 'Couldn\'t load your products.';

  @override
  String get productCreated => 'Product created.';

  @override
  String get productUpdated => 'Product updated.';

  @override
  String get productDeleted => 'Product deleted.';

  @override
  String get movementRecorded => 'Movement recorded.';

  @override
  String get openMenu => 'Open menu';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get todaySummary => 'Today at a glance';

  @override
  String get summaryReceived => 'Received';

  @override
  String get summarySold => 'Sold';

  @override
  String get summaryAdjusted => 'Adjusted';

  @override
  String summaryMovements(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count movements today',
      one: '1 movement today',
      zero: 'No movements yet today',
    );
    return '$_temp0';
  }

  @override
  String get edit => 'Edit';

  @override
  String get more => 'More';

  @override
  String get deleteProduct => 'Delete product';

  @override
  String get deleteProductTitle => 'Delete product?';

  @override
  String deleteProductBody(String name) {
    return 'This will remove $name from the product list.';
  }

  @override
  String get reorderWhen => 'Reorder when it reaches ';

  @override
  String get reasonReceived => 'Received';

  @override
  String get reasonSold => 'Sold';

  @override
  String get reasonAdjust => 'Adjust';

  @override
  String get history => 'History';

  @override
  String get seeAll => 'See all';

  @override
  String get showLess => 'Show less';

  @override
  String get noMovements => 'No movements yet.';

  @override
  String historyReceived(int amount) {
    return 'Received $amount';
  }

  @override
  String historySold(int amount) {
    return 'Sold $amount';
  }

  @override
  String historyAdjusted(String amount) {
    return 'Adjusted $amount';
  }

  @override
  String historyCounted(String amount) {
    return 'Stock count $amount';
  }

  @override
  String get productGone => 'This product was deleted.';

  @override
  String get recordMovement => 'Record movement';

  @override
  String nowInStock(int stock, String unit) {
    return 'Now in stock: $stock $unit';
  }

  @override
  String questionReceived(String unit) {
    return 'How many $unit arrived?';
  }

  @override
  String questionSold(String unit) {
    return 'How many $unit sold?';
  }

  @override
  String questionAdjust(String unit) {
    return 'Adjust by how many $unit?';
  }

  @override
  String get decrease => 'Decrease';

  @override
  String get increase => 'Increase';

  @override
  String get stockAfterSaving => 'Stock after saving';

  @override
  String get noteOptional => 'Note (optional)';

  @override
  String get noteHintReceived => 'e.g. delivery from supplier';

  @override
  String get noteHintSold => 'e.g. sold to a regular';

  @override
  String get noteHintAdjust => 'e.g. 2 bottles broken';

  @override
  String saveReceived(int amount) {
    return 'Save · received $amount';
  }

  @override
  String saveSold(int amount) {
    return 'Save · sold $amount';
  }

  @override
  String saveAdjusted(String amount) {
    return 'Save · adjust $amount';
  }

  @override
  String get savedLocallyHint =>
      'Saved on this phone right away. It syncs when you\'re online.';

  @override
  String get editProduct => 'Edit product';

  @override
  String get addPhoto => 'Add a photo';

  @override
  String get cameraOrGallery => 'Camera or gallery';

  @override
  String get changePhoto => 'Change photo';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get productName => 'Name';

  @override
  String get barcode => 'Barcode';

  @override
  String get unit => 'Unit';

  @override
  String get reorderAt => 'Reorder at';

  @override
  String get reorderHelp =>
      'You\'ll get an alert when stock drops to this number.';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get scanToFill => 'Scan the barcode';

  @override
  String get suggestFromPhoto => 'Suggest name from photo';

  @override
  String get suggestionApplied =>
      'Filled in from the label. Check it before saving.';

  @override
  String get suggestionFailed =>
      'Couldn\'t read the label. Type the name instead.';

  @override
  String get scanBarcode => 'Scan barcode';

  @override
  String get pointCamera => 'Point the camera at the barcode';

  @override
  String get typeNumberInstead => 'Type the number instead';

  @override
  String get typeBarcodeTitle => 'Type the barcode';

  @override
  String get find => 'Find';

  @override
  String get flashOn => 'Flash on';

  @override
  String get flashOff => 'Flash off';

  @override
  String get found => 'Found';

  @override
  String get notFound => 'Not found';

  @override
  String get noProductWithBarcode => 'No product has this barcode yet.';

  @override
  String inStockCount(int stock, String unit) {
    return '$stock $unit in stock';
  }

  @override
  String get cameraPermissionDenied =>
      'Camera access is off. Allow it in settings, or type the number.';

  @override
  String get openSettings => 'Open settings';

  @override
  String get cameraUnavailable => 'No camera here. Type the number instead.';

  @override
  String get stockCount => 'Stock count';

  @override
  String countedOf(int total) {
    return 'of $total counted';
  }

  @override
  String get justScanned => 'Just scanned';

  @override
  String expectedQty(int count) {
    return 'Expected $count';
  }

  @override
  String get oneLess => 'One less';

  @override
  String get oneMore => 'One more';

  @override
  String get differences => 'Differences';

  @override
  String get allCounted => 'All counted';

  @override
  String get noDifferences => 'No differences so far.';

  @override
  String get nothingCounted =>
      'Nothing counted yet. Scan the first item on the shelf.';

  @override
  String get finishCount => 'Finish count';

  @override
  String get scanNext => 'Scan next';

  @override
  String expectedCounted(int expected, int counted) {
    return 'Expected $expected · Counted $counted';
  }

  @override
  String get finishCountTitle => 'Finish count?';

  @override
  String get finishCountNoDiff => 'No differences found. Stock stays as it is.';

  @override
  String finishCountBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count products',
      one: '1 product',
    );
    return 'Stock will be corrected for $_temp0.';
  }

  @override
  String get commitCount => 'Save count';

  @override
  String get keepCounting => 'Keep counting';

  @override
  String get countSaved => 'Count saved.';

  @override
  String get leaveCountTitle => 'Leave the count?';

  @override
  String get leaveCountBody =>
      'Your count is saved on this phone. Continue it later, or discard it.';

  @override
  String get continueLater => 'Continue later';

  @override
  String get discardCount => 'Discard';

  @override
  String unknownBarcode(String code) {
    return 'No product has barcode $code.';
  }

  @override
  String get everythingCounted => 'Everything is counted.';

  @override
  String get countInProgressBanner =>
      'Stock count in progress — movements are paused.';

  @override
  String get resumeCount => 'Resume';

  @override
  String get mostUrgentFirst => 'Most urgent first';

  @override
  String get allStockedUp => 'All stocked up';

  @override
  String itemsToRestock(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items to restock',
      one: '1 item to restock',
    );
    return '$_temp0';
  }

  @override
  String get noRestockNeeded => 'No products need restocking.';

  @override
  String get belowReorderPoint => 'Below reorder point';

  @override
  String ofReorder(int point) {
    return 'of $point';
  }

  @override
  String get recordReceived => 'Record received';

  @override
  String get reorderIdeas => 'Reorder ideas';

  @override
  String get reorderIdeasFailed => 'Couldn\'t draft suggestions right now.';

  @override
  String get syncTitle => 'Sync';

  @override
  String get youreOffline => 'You\'re offline';

  @override
  String get youreOnline => 'You\'re online';

  @override
  String get syncing => 'Syncing…';

  @override
  String get allSynced => 'Everything is synced';

  @override
  String lastSynced(String time) {
    return 'Last synced $time';
  }

  @override
  String get neverSynced => 'Not synced yet';

  @override
  String pendingOffline(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count changes are safe on this phone. They\'ll upload by themselves when you\'re back online.',
      one:
          '1 change is safe on this phone. It will upload by itself when you\'re back online.',
      zero: 'Nothing is waiting. New changes are saved on this phone.',
    );
    return '$_temp0';
  }

  @override
  String pendingOnline(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes are waiting to upload.',
      one: '1 change is waiting to upload.',
      zero: 'All your changes are on the server.',
    );
    return '$_temp0';
  }

  @override
  String get trySyncNow => 'Try sync now';

  @override
  String get syncNow => 'Sync now';

  @override
  String get syncFailed => 'Sync didn\'t finish. It will retry by itself.';

  @override
  String get syncDone => 'Sync complete.';

  @override
  String waitingToUpload(int count) {
    return 'Waiting to upload · $count';
  }

  @override
  String needsALook(int count) {
    return 'Needs a look · $count';
  }

  @override
  String conflictTitle(String name) {
    return '$name was changed on two phones';
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
    return 'Kept “$kept” ($keptBy, $keptAt). Replaced “$lost” ($lostBy, $lostAt).';
  }

  @override
  String get dismiss => 'Dismiss';

  @override
  String pendingEdited(String name) {
    return 'Edited · $name';
  }

  @override
  String pendingMovement(String action, String name) {
    return '$action · $name';
  }

  @override
  String get demoModeTitle => 'Demo mode';

  @override
  String get demoModeBody =>
      'This build has no server, so everything stays on this phone.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get staffAccounts => 'Staff accounts';

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleStaff => 'Staff';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutTitle => 'Sign out?';

  @override
  String get signOutBody =>
      'Data is removed from this phone so the next person starts clean.';

  @override
  String signOutPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes have not synced yet and will be lost.',
      one: '1 change has not synced yet and will be lost.',
    );
    return '$_temp0';
  }

  @override
  String appVersion(String version) {
    return 'Jerd $version';
  }

  @override
  String get addStaff => 'Add staff';

  @override
  String get staffName => 'Name';

  @override
  String get role => 'Role';

  @override
  String get staffAdded => 'Account created.';

  @override
  String get staffRemoved => 'Account removed.';

  @override
  String get removeStaffTitle => 'Remove account?';

  @override
  String removeStaffBody(String name) {
    return '$name will no longer be able to sign in.';
  }

  @override
  String get remove => 'Remove';

  @override
  String get ownerOnlyStaff => 'Only the owner can add or remove accounts.';

  @override
  String updateAvailable(String version) {
    return 'Update available: $version';
  }

  @override
  String get updateRequired =>
      'This version is too old. Please update to keep syncing.';

  @override
  String get updateNow => 'Update';
}
