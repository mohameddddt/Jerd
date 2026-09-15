import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Jerd'**
  String get appName;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the server. Check your connection.'**
  String get errorNetwork;

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Wrong email or password.'**
  String get errorInvalidCredentials;

  /// No description provided for @errorDuplicateBarcode.
  ///
  /// In en, this message translates to:
  /// **'This barcode already belongs to {name}.'**
  String errorDuplicateBarcode(String name);

  /// No description provided for @errorValidation.
  ///
  /// In en, this message translates to:
  /// **'Please check the highlighted fields.'**
  String get errorValidation;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'This item no longer exists.'**
  String get errorNotFound;

  /// No description provided for @errorCountInProgress.
  ///
  /// In en, this message translates to:
  /// **'A stock count is in progress. Finish it before recording movements.'**
  String get errorCountInProgress;

  /// No description provided for @errorPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Only the shop owner can do this.'**
  String get errorPermissionDenied;

  /// No description provided for @errorServerNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'No server is set up for this build. Everything stays on this phone.'**
  String get errorServerNotConfigured;

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'The server refused the request: {message}'**
  String errorServer(String message);

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorUnknown;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get fieldRequired;

  /// No description provided for @fieldInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email.'**
  String get fieldInvalidEmail;

  /// No description provided for @fieldPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least {min} characters.'**
  String fieldPasswordTooShort(int min);

  /// No description provided for @fieldInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number.'**
  String get fieldInvalidNumber;

  /// No description provided for @fieldNegative.
  ///
  /// In en, this message translates to:
  /// **'This can\'t be negative.'**
  String get fieldNegative;

  /// No description provided for @fieldInvalidBarcode.
  ///
  /// In en, this message translates to:
  /// **'A barcode is 4 to 14 digits.'**
  String get fieldInvalidBarcode;

  /// No description provided for @fieldZeroQuantity.
  ///
  /// In en, this message translates to:
  /// **'Enter a quantity other than zero.'**
  String get fieldZeroQuantity;

  /// No description provided for @fieldTooLong.
  ///
  /// In en, this message translates to:
  /// **'This is too long.'**
  String get fieldTooLong;

  /// No description provided for @fieldDuplicate.
  ///
  /// In en, this message translates to:
  /// **'This is already in use.'**
  String get fieldDuplicate;

  /// No description provided for @loginTagline.
  ///
  /// In en, this message translates to:
  /// **'Count your stock,\neven with no signal.'**
  String get loginTagline;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @forgotPasswordHelp.
  ///
  /// In en, this message translates to:
  /// **'Ask your shop owner to reset your password.'**
  String get forgotPasswordHelp;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'No account? Ask your shop owner to add you.'**
  String get noAccount;

  /// No description provided for @demoAccounts.
  ///
  /// In en, this message translates to:
  /// **'Demo: {email} / {password}'**
  String demoAccounts(String email, String password);

  /// No description provided for @navProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get navProducts;

  /// No description provided for @navCount.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get navCount;

  /// No description provided for @navAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get navAlerts;

  /// No description provided for @navSync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get navSync;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @productsTitle.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get productsTitle;

  /// No description provided for @shopItems.
  ///
  /// In en, this message translates to:
  /// **'{shop} · {count, plural, =1{1 item} other{{count} items}}'**
  String shopItems(String shop, int count);

  /// No description provided for @myShop.
  ///
  /// In en, this message translates to:
  /// **'My shop'**
  String get myShop;

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Changes are saved on this phone and will sync later.'**
  String get offlineBanner;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search name or barcode'**
  String get searchHint;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterLow.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get filterLow;

  /// No description provided for @filterOut.
  ///
  /// In en, this message translates to:
  /// **'Out'**
  String get filterOut;

  /// No description provided for @noProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No products found.'**
  String get noProductsFound;

  /// No description provided for @emptyProductsTitle.
  ///
  /// In en, this message translates to:
  /// **'No products yet'**
  String get emptyProductsTitle;

  /// No description provided for @emptyProductsBody.
  ///
  /// In en, this message translates to:
  /// **'Scan a barcode or tap + to add your first product.'**
  String get emptyProductsBody;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add product'**
  String get addProduct;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @badgeLow.
  ///
  /// In en, this message translates to:
  /// **'Low · reorder at {point}'**
  String badgeLow(int point);

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get outOfStock;

  /// No description provided for @lowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get lowStock;

  /// No description provided for @inStock.
  ///
  /// In en, this message translates to:
  /// **'In stock'**
  String get inStock;

  /// No description provided for @loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your products.'**
  String get loadFailed;

  /// No description provided for @productCreated.
  ///
  /// In en, this message translates to:
  /// **'Product created.'**
  String get productCreated;

  /// No description provided for @productUpdated.
  ///
  /// In en, this message translates to:
  /// **'Product updated.'**
  String get productUpdated;

  /// No description provided for @productDeleted.
  ///
  /// In en, this message translates to:
  /// **'Product deleted.'**
  String get productDeleted;

  /// No description provided for @movementRecorded.
  ///
  /// In en, this message translates to:
  /// **'Movement recorded.'**
  String get movementRecorded;

  /// No description provided for @openMenu.
  ///
  /// In en, this message translates to:
  /// **'Open menu'**
  String get openMenu;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @todaySummary.
  ///
  /// In en, this message translates to:
  /// **'Today at a glance'**
  String get todaySummary;

  /// No description provided for @summaryReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get summaryReceived;

  /// No description provided for @summarySold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get summarySold;

  /// No description provided for @summaryAdjusted.
  ///
  /// In en, this message translates to:
  /// **'Adjusted'**
  String get summaryAdjusted;

  /// No description provided for @summaryMovements.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No movements yet today} =1{1 movement today} other{{count} movements today}}'**
  String summaryMovements(int count);

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @deleteProduct.
  ///
  /// In en, this message translates to:
  /// **'Delete product'**
  String get deleteProduct;

  /// No description provided for @deleteProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete product?'**
  String get deleteProductTitle;

  /// No description provided for @deleteProductBody.
  ///
  /// In en, this message translates to:
  /// **'This will remove {name} from the product list.'**
  String deleteProductBody(String name);

  /// No description provided for @reorderWhen.
  ///
  /// In en, this message translates to:
  /// **'Reorder when it reaches '**
  String get reorderWhen;

  /// No description provided for @reasonReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get reasonReceived;

  /// No description provided for @reasonSold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get reasonSold;

  /// No description provided for @reasonAdjust.
  ///
  /// In en, this message translates to:
  /// **'Adjust'**
  String get reasonAdjust;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLess;

  /// No description provided for @noMovements.
  ///
  /// In en, this message translates to:
  /// **'No movements yet.'**
  String get noMovements;

  /// No description provided for @historyReceived.
  ///
  /// In en, this message translates to:
  /// **'Received {amount}'**
  String historyReceived(int amount);

  /// No description provided for @historySold.
  ///
  /// In en, this message translates to:
  /// **'Sold {amount}'**
  String historySold(int amount);

  /// No description provided for @historyAdjusted.
  ///
  /// In en, this message translates to:
  /// **'Adjusted {amount}'**
  String historyAdjusted(String amount);

  /// No description provided for @historyCounted.
  ///
  /// In en, this message translates to:
  /// **'Stock count {amount}'**
  String historyCounted(String amount);

  /// No description provided for @productGone.
  ///
  /// In en, this message translates to:
  /// **'This product was deleted.'**
  String get productGone;

  /// No description provided for @recordMovement.
  ///
  /// In en, this message translates to:
  /// **'Record movement'**
  String get recordMovement;

  /// No description provided for @nowInStock.
  ///
  /// In en, this message translates to:
  /// **'Now in stock: {stock} {unit}'**
  String nowInStock(int stock, String unit);

  /// No description provided for @questionReceived.
  ///
  /// In en, this message translates to:
  /// **'How many {unit} arrived?'**
  String questionReceived(String unit);

  /// No description provided for @questionSold.
  ///
  /// In en, this message translates to:
  /// **'How many {unit} sold?'**
  String questionSold(String unit);

  /// No description provided for @questionAdjust.
  ///
  /// In en, this message translates to:
  /// **'Adjust by how many {unit}?'**
  String questionAdjust(String unit);

  /// No description provided for @decrease.
  ///
  /// In en, this message translates to:
  /// **'Decrease'**
  String get decrease;

  /// No description provided for @increase.
  ///
  /// In en, this message translates to:
  /// **'Increase'**
  String get increase;

  /// No description provided for @stockAfterSaving.
  ///
  /// In en, this message translates to:
  /// **'Stock after saving'**
  String get stockAfterSaving;

  /// No description provided for @noteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteOptional;

  /// No description provided for @noteHintReceived.
  ///
  /// In en, this message translates to:
  /// **'e.g. delivery from supplier'**
  String get noteHintReceived;

  /// No description provided for @noteHintSold.
  ///
  /// In en, this message translates to:
  /// **'e.g. sold to a regular'**
  String get noteHintSold;

  /// No description provided for @noteHintAdjust.
  ///
  /// In en, this message translates to:
  /// **'e.g. 2 bottles broken'**
  String get noteHintAdjust;

  /// No description provided for @saveReceived.
  ///
  /// In en, this message translates to:
  /// **'Save · received {amount}'**
  String saveReceived(int amount);

  /// No description provided for @saveSold.
  ///
  /// In en, this message translates to:
  /// **'Save · sold {amount}'**
  String saveSold(int amount);

  /// No description provided for @saveAdjusted.
  ///
  /// In en, this message translates to:
  /// **'Save · adjust {amount}'**
  String saveAdjusted(String amount);

  /// No description provided for @savedLocallyHint.
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone right away. It syncs when you\'re online.'**
  String get savedLocallyHint;

  /// No description provided for @editProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit product'**
  String get editProduct;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get addPhoto;

  /// No description provided for @cameraOrGallery.
  ///
  /// In en, this message translates to:
  /// **'Camera or gallery'**
  String get cameraOrGallery;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get changePhoto;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhoto;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get productName;

  /// No description provided for @barcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get barcode;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @reorderAt.
  ///
  /// In en, this message translates to:
  /// **'Reorder at'**
  String get reorderAt;

  /// No description provided for @reorderHelp.
  ///
  /// In en, this message translates to:
  /// **'You\'ll get an alert when stock drops to this number.'**
  String get reorderHelp;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @scanToFill.
  ///
  /// In en, this message translates to:
  /// **'Scan the barcode'**
  String get scanToFill;

  /// No description provided for @suggestFromPhoto.
  ///
  /// In en, this message translates to:
  /// **'Suggest name from photo'**
  String get suggestFromPhoto;

  /// No description provided for @suggestionApplied.
  ///
  /// In en, this message translates to:
  /// **'Filled in from the label. Check it before saving.'**
  String get suggestionApplied;

  /// No description provided for @suggestionFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read the label. Type the name instead.'**
  String get suggestionFailed;

  /// No description provided for @scanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode'**
  String get scanBarcode;

  /// No description provided for @pointCamera.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the barcode'**
  String get pointCamera;

  /// No description provided for @typeNumberInstead.
  ///
  /// In en, this message translates to:
  /// **'Type the number instead'**
  String get typeNumberInstead;

  /// No description provided for @typeBarcodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Type the barcode'**
  String get typeBarcodeTitle;

  /// No description provided for @find.
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get find;

  /// No description provided for @flashOn.
  ///
  /// In en, this message translates to:
  /// **'Flash on'**
  String get flashOn;

  /// No description provided for @flashOff.
  ///
  /// In en, this message translates to:
  /// **'Flash off'**
  String get flashOff;

  /// No description provided for @found.
  ///
  /// In en, this message translates to:
  /// **'Found'**
  String get found;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get notFound;

  /// No description provided for @noProductWithBarcode.
  ///
  /// In en, this message translates to:
  /// **'No product has this barcode yet.'**
  String get noProductWithBarcode;

  /// No description provided for @inStockCount.
  ///
  /// In en, this message translates to:
  /// **'{stock} {unit} in stock'**
  String inStockCount(int stock, String unit);

  /// No description provided for @cameraPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera access is off. Allow it in settings, or type the number.'**
  String get cameraPermissionDenied;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @cameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No camera here. Type the number instead.'**
  String get cameraUnavailable;

  /// No description provided for @stockCount.
  ///
  /// In en, this message translates to:
  /// **'Stock count'**
  String get stockCount;

  /// No description provided for @countedOf.
  ///
  /// In en, this message translates to:
  /// **'of {total} counted'**
  String countedOf(int total);

  /// No description provided for @justScanned.
  ///
  /// In en, this message translates to:
  /// **'Just scanned'**
  String get justScanned;

  /// No description provided for @expectedQty.
  ///
  /// In en, this message translates to:
  /// **'Expected {count}'**
  String expectedQty(int count);

  /// No description provided for @oneLess.
  ///
  /// In en, this message translates to:
  /// **'One less'**
  String get oneLess;

  /// No description provided for @oneMore.
  ///
  /// In en, this message translates to:
  /// **'One more'**
  String get oneMore;

  /// No description provided for @differences.
  ///
  /// In en, this message translates to:
  /// **'Differences'**
  String get differences;

  /// No description provided for @allCounted.
  ///
  /// In en, this message translates to:
  /// **'All counted'**
  String get allCounted;

  /// No description provided for @noDifferences.
  ///
  /// In en, this message translates to:
  /// **'No differences so far.'**
  String get noDifferences;

  /// No description provided for @nothingCounted.
  ///
  /// In en, this message translates to:
  /// **'Nothing counted yet. Scan the first item on the shelf.'**
  String get nothingCounted;

  /// No description provided for @finishCount.
  ///
  /// In en, this message translates to:
  /// **'Finish count'**
  String get finishCount;

  /// No description provided for @scanNext.
  ///
  /// In en, this message translates to:
  /// **'Scan next'**
  String get scanNext;

  /// No description provided for @expectedCounted.
  ///
  /// In en, this message translates to:
  /// **'Expected {expected} · Counted {counted}'**
  String expectedCounted(int expected, int counted);

  /// No description provided for @finishCountTitle.
  ///
  /// In en, this message translates to:
  /// **'Finish count?'**
  String get finishCountTitle;

  /// No description provided for @finishCountNoDiff.
  ///
  /// In en, this message translates to:
  /// **'No differences found. Stock stays as it is.'**
  String get finishCountNoDiff;

  /// No description provided for @finishCountBody.
  ///
  /// In en, this message translates to:
  /// **'Stock will be corrected for {count, plural, =1{1 product} other{{count} products}}.'**
  String finishCountBody(int count);

  /// No description provided for @commitCount.
  ///
  /// In en, this message translates to:
  /// **'Save count'**
  String get commitCount;

  /// No description provided for @keepCounting.
  ///
  /// In en, this message translates to:
  /// **'Keep counting'**
  String get keepCounting;

  /// No description provided for @countSaved.
  ///
  /// In en, this message translates to:
  /// **'Count saved.'**
  String get countSaved;

  /// No description provided for @leaveCountTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave the count?'**
  String get leaveCountTitle;

  /// No description provided for @leaveCountBody.
  ///
  /// In en, this message translates to:
  /// **'Your count is saved on this phone. Continue it later, or discard it.'**
  String get leaveCountBody;

  /// No description provided for @continueLater.
  ///
  /// In en, this message translates to:
  /// **'Continue later'**
  String get continueLater;

  /// No description provided for @discardCount.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discardCount;

  /// No description provided for @unknownBarcode.
  ///
  /// In en, this message translates to:
  /// **'No product has barcode {code}.'**
  String unknownBarcode(String code);

  /// No description provided for @everythingCounted.
  ///
  /// In en, this message translates to:
  /// **'Everything is counted.'**
  String get everythingCounted;

  /// No description provided for @countInProgressBanner.
  ///
  /// In en, this message translates to:
  /// **'Stock count in progress — movements are paused.'**
  String get countInProgressBanner;

  /// No description provided for @resumeCount.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resumeCount;

  /// No description provided for @mostUrgentFirst.
  ///
  /// In en, this message translates to:
  /// **'Most urgent first'**
  String get mostUrgentFirst;

  /// No description provided for @allStockedUp.
  ///
  /// In en, this message translates to:
  /// **'All stocked up'**
  String get allStockedUp;

  /// No description provided for @itemsToRestock.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item to restock} other{{count} items to restock}}'**
  String itemsToRestock(int count);

  /// No description provided for @noRestockNeeded.
  ///
  /// In en, this message translates to:
  /// **'No products need restocking.'**
  String get noRestockNeeded;

  /// No description provided for @belowReorderPoint.
  ///
  /// In en, this message translates to:
  /// **'Below reorder point'**
  String get belowReorderPoint;

  /// No description provided for @ofReorder.
  ///
  /// In en, this message translates to:
  /// **'of {point}'**
  String ofReorder(int point);

  /// No description provided for @recordReceived.
  ///
  /// In en, this message translates to:
  /// **'Record received'**
  String get recordReceived;

  /// No description provided for @reorderIdeas.
  ///
  /// In en, this message translates to:
  /// **'Reorder ideas'**
  String get reorderIdeas;

  /// No description provided for @reorderIdeasFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t draft suggestions right now.'**
  String get reorderIdeasFailed;

  /// No description provided for @syncTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get syncTitle;

  /// No description provided for @youreOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get youreOffline;

  /// No description provided for @youreOnline.
  ///
  /// In en, this message translates to:
  /// **'You\'re online'**
  String get youreOnline;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get syncing;

  /// No description provided for @allSynced.
  ///
  /// In en, this message translates to:
  /// **'Everything is synced'**
  String get allSynced;

  /// No description provided for @lastSynced.
  ///
  /// In en, this message translates to:
  /// **'Last synced {time}'**
  String lastSynced(String time);

  /// No description provided for @neverSynced.
  ///
  /// In en, this message translates to:
  /// **'Not synced yet'**
  String get neverSynced;

  /// No description provided for @pendingOffline.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing is waiting. New changes are saved on this phone.} =1{1 change is safe on this phone. It will upload by itself when you\'re back online.} other{{count} changes are safe on this phone. They\'ll upload by themselves when you\'re back online.}}'**
  String pendingOffline(int count);

  /// No description provided for @pendingOnline.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{All your changes are on the server.} =1{1 change is waiting to upload.} other{{count} changes are waiting to upload.}}'**
  String pendingOnline(int count);

  /// No description provided for @trySyncNow.
  ///
  /// In en, this message translates to:
  /// **'Try sync now'**
  String get trySyncNow;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync didn\'t finish. It will retry by itself.'**
  String get syncFailed;

  /// No description provided for @syncDone.
  ///
  /// In en, this message translates to:
  /// **'Sync complete.'**
  String get syncDone;

  /// No description provided for @waitingToUpload.
  ///
  /// In en, this message translates to:
  /// **'Waiting to upload · {count}'**
  String waitingToUpload(int count);

  /// No description provided for @needsALook.
  ///
  /// In en, this message translates to:
  /// **'Needs a look · {count}'**
  String needsALook(int count);

  /// No description provided for @conflictTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} was changed on two phones'**
  String conflictTitle(String name);

  /// No description provided for @conflictDetail.
  ///
  /// In en, this message translates to:
  /// **'Kept “{kept}” ({keptBy}, {keptAt}). Replaced “{lost}” ({lostBy}, {lostAt}).'**
  String conflictDetail(
    String kept,
    String keptBy,
    String keptAt,
    String lost,
    String lostBy,
    String lostAt,
  );

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @pendingEdited.
  ///
  /// In en, this message translates to:
  /// **'Edited · {name}'**
  String pendingEdited(String name);

  /// No description provided for @pendingMovement.
  ///
  /// In en, this message translates to:
  /// **'{action} · {name}'**
  String pendingMovement(String action, String name);

  /// No description provided for @demoModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Demo mode'**
  String get demoModeTitle;

  /// No description provided for @demoModeBody.
  ///
  /// In en, this message translates to:
  /// **'This build has no server, so everything stays on this phone.'**
  String get demoModeBody;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @staffAccounts.
  ///
  /// In en, this message translates to:
  /// **'Staff accounts'**
  String get staffAccounts;

  /// No description provided for @roleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get roleOwner;

  /// No description provided for @roleStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get roleStaff;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutTitle;

  /// No description provided for @signOutBody.
  ///
  /// In en, this message translates to:
  /// **'Data is removed from this phone so the next person starts clean.'**
  String get signOutBody;

  /// No description provided for @signOutPending.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change has not synced yet and will be lost.} other{{count} changes have not synced yet and will be lost.}}'**
  String signOutPending(int count);

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Jerd {version}'**
  String appVersion(String version);

  /// No description provided for @addStaff.
  ///
  /// In en, this message translates to:
  /// **'Add staff'**
  String get addStaff;

  /// No description provided for @staffName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get staffName;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @staffAdded.
  ///
  /// In en, this message translates to:
  /// **'Account created.'**
  String get staffAdded;

  /// No description provided for @staffRemoved.
  ///
  /// In en, this message translates to:
  /// **'Account removed.'**
  String get staffRemoved;

  /// No description provided for @removeStaffTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove account?'**
  String get removeStaffTitle;

  /// No description provided for @removeStaffBody.
  ///
  /// In en, this message translates to:
  /// **'{name} will no longer be able to sign in.'**
  String removeStaffBody(String name);

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @ownerOnlyStaff.
  ///
  /// In en, this message translates to:
  /// **'Only the owner can add or remove accounts.'**
  String get ownerOnlyStaff;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available: {version}'**
  String updateAvailable(String version);

  /// No description provided for @updateRequired.
  ///
  /// In en, this message translates to:
  /// **'This version is too old. Please update to keep syncing.'**
  String get updateRequired;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateNow;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
