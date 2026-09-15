// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Jerd';

  @override
  String get cancel => 'Annuler';

  @override
  String get confirm => 'Confirmer';

  @override
  String get delete => 'Supprimer';

  @override
  String get save => 'Enregistrer';

  @override
  String get retry => 'Réessayer';

  @override
  String get close => 'Fermer';

  @override
  String get clear => 'Effacer';

  @override
  String get later => 'Plus tard';

  @override
  String get you => 'Vous';

  @override
  String get errorNetwork => 'Serveur injoignable. Vérifiez votre connexion.';

  @override
  String get errorInvalidCredentials => 'E-mail ou mot de passe incorrect.';

  @override
  String errorDuplicateBarcode(String name) {
    return 'Ce code-barres appartient déjà à $name.';
  }

  @override
  String get errorValidation => 'Vérifiez les champs signalés.';

  @override
  String get errorNotFound => 'Cet élément n\'existe plus.';

  @override
  String get errorCountInProgress =>
      'Un inventaire est en cours. Terminez-le avant d\'enregistrer des mouvements.';

  @override
  String get errorPermissionDenied =>
      'Seul le propriétaire de la boutique peut faire cela.';

  @override
  String get errorServerNotConfigured =>
      'Aucun serveur n\'est configuré. Tout reste sur ce téléphone.';

  @override
  String errorServer(String message) {
    return 'Le serveur a refusé la requête : $message';
  }

  @override
  String get errorUnknown => 'Une erreur s\'est produite. Veuillez réessayer.';

  @override
  String get fieldRequired => 'Ce champ est obligatoire.';

  @override
  String get fieldInvalidEmail => 'Saisissez un e-mail valide.';

  @override
  String fieldPasswordTooShort(int min) {
    return 'Le mot de passe doit contenir au moins $min caractères.';
  }

  @override
  String get fieldInvalidNumber => 'Saisissez un nombre valide.';

  @override
  String get fieldNegative => 'La valeur ne peut pas être négative.';

  @override
  String get fieldInvalidBarcode => 'Un code-barres compte de 4 à 14 chiffres.';

  @override
  String get fieldZeroQuantity => 'Saisissez une quantité différente de zéro.';

  @override
  String get fieldTooLong => 'C\'est trop long.';

  @override
  String get fieldDuplicate => 'Déjà utilisé.';

  @override
  String get loginTagline => 'Comptez votre stock,\nmême sans réseau.';

  @override
  String get signIn => 'Se connecter';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get showPassword => 'Afficher le mot de passe';

  @override
  String get hidePassword => 'Masquer le mot de passe';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get forgotPasswordHelp =>
      'Demandez au propriétaire de la boutique de réinitialiser votre mot de passe.';

  @override
  String get noAccount =>
      'Pas de compte ? Demandez au propriétaire de vous ajouter.';

  @override
  String demoAccounts(String email, String password) {
    return 'Démo : $email / $password';
  }

  @override
  String get navProducts => 'Produits';

  @override
  String get navCount => 'Inventaire';

  @override
  String get navAlerts => 'Alertes';

  @override
  String get navSync => 'Synchro';

  @override
  String get navSettings => 'Réglages';

  @override
  String get productsTitle => 'Produits';

  @override
  String shopItems(String shop, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count articles',
      one: '1 article',
      zero: 'aucun article',
    );
    return '$shop · $_temp0';
  }

  @override
  String get myShop => 'Ma boutique';

  @override
  String get offlineBanner =>
      'Vous êtes hors ligne. Les modifications sont enregistrées sur ce téléphone et seront synchronisées plus tard.';

  @override
  String get searchHint => 'Nom ou code-barres';

  @override
  String get filterAll => 'Tous';

  @override
  String get filterLow => 'Stock bas';

  @override
  String get filterOut => 'Épuisés';

  @override
  String get noProductsFound => 'Aucun produit trouvé.';

  @override
  String get emptyProductsTitle => 'Aucun produit pour l\'instant';

  @override
  String get emptyProductsBody =>
      'Scannez un code-barres ou appuyez sur + pour ajouter votre premier produit.';

  @override
  String get addProduct => 'Ajouter un produit';

  @override
  String get scan => 'Scanner';

  @override
  String badgeLow(int point) {
    return 'Bas · commander à $point';
  }

  @override
  String get outOfStock => 'Épuisé';

  @override
  String get lowStock => 'Stock bas';

  @override
  String get inStock => 'En stock';

  @override
  String get loadFailed => 'Impossible de charger vos produits.';

  @override
  String get productCreated => 'Produit créé.';

  @override
  String get productUpdated => 'Produit mis à jour.';

  @override
  String get productDeleted => 'Produit supprimé.';

  @override
  String get movementRecorded => 'Mouvement enregistré.';

  @override
  String get openMenu => 'Ouvrir le menu';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get yesterday => 'Hier';

  @override
  String get todaySummary => 'Aujourd\'hui en bref';

  @override
  String get summaryReceived => 'Reçus';

  @override
  String get summarySold => 'Vendus';

  @override
  String get summaryAdjusted => 'Ajustés';

  @override
  String summaryMovements(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mouvements aujourd\'hui',
      one: '1 mouvement aujourd\'hui',
      zero: 'Aucun mouvement aujourd\'hui',
    );
    return '$_temp0';
  }

  @override
  String get edit => 'Modifier';

  @override
  String get more => 'Plus';

  @override
  String get deleteProduct => 'Supprimer le produit';

  @override
  String get deleteProductTitle => 'Supprimer le produit ?';

  @override
  String deleteProductBody(String name) {
    return '$name sera retiré de la liste des produits.';
  }

  @override
  String get reorderWhen => 'Commander quand il atteint ';

  @override
  String get reasonReceived => 'Reçu';

  @override
  String get reasonSold => 'Vendu';

  @override
  String get reasonAdjust => 'Ajuster';

  @override
  String get history => 'Historique';

  @override
  String get seeAll => 'Tout voir';

  @override
  String get showLess => 'Voir moins';

  @override
  String get noMovements => 'Aucun mouvement pour l\'instant.';

  @override
  String historyReceived(int amount) {
    return 'Reçu $amount';
  }

  @override
  String historySold(int amount) {
    return 'Vendu $amount';
  }

  @override
  String historyAdjusted(String amount) {
    return 'Ajusté $amount';
  }

  @override
  String historyCounted(String amount) {
    return 'Inventaire $amount';
  }

  @override
  String get productGone => 'Ce produit a été supprimé.';

  @override
  String get recordMovement => 'Enregistrer un mouvement';

  @override
  String nowInStock(int stock, String unit) {
    return 'En stock : $stock $unit';
  }

  @override
  String questionReceived(String unit) {
    return 'Combien de $unit reçus ?';
  }

  @override
  String questionSold(String unit) {
    return 'Combien de $unit vendus ?';
  }

  @override
  String questionAdjust(String unit) {
    return 'Ajuster de combien de $unit ?';
  }

  @override
  String get decrease => 'Diminuer';

  @override
  String get increase => 'Augmenter';

  @override
  String get stockAfterSaving => 'Stock après enregistrement';

  @override
  String get noteOptional => 'Note (facultatif)';

  @override
  String get noteHintReceived => 'ex. livraison du fournisseur';

  @override
  String get noteHintSold => 'ex. vendu à un habitué';

  @override
  String get noteHintAdjust => 'ex. 2 bouteilles cassées';

  @override
  String saveReceived(int amount) {
    return 'Enregistrer · reçu $amount';
  }

  @override
  String saveSold(int amount) {
    return 'Enregistrer · vendu $amount';
  }

  @override
  String saveAdjusted(String amount) {
    return 'Enregistrer · ajuster $amount';
  }

  @override
  String get savedLocallyHint =>
      'Enregistré tout de suite sur ce téléphone. Synchronisé dès que vous êtes en ligne.';

  @override
  String get editProduct => 'Modifier le produit';

  @override
  String get addPhoto => 'Ajouter une photo';

  @override
  String get cameraOrGallery => 'Appareil photo ou galerie';

  @override
  String get changePhoto => 'Changer la photo';

  @override
  String get removePhoto => 'Retirer la photo';

  @override
  String get takePhoto => 'Prendre une photo';

  @override
  String get chooseFromGallery => 'Choisir dans la galerie';

  @override
  String get productName => 'Nom';

  @override
  String get barcode => 'Code-barres';

  @override
  String get unit => 'Unité';

  @override
  String get reorderAt => 'Commander à';

  @override
  String get reorderHelp =>
      'Vous recevrez une alerte quand le stock descend à ce nombre.';

  @override
  String get saveChanges => 'Enregistrer';

  @override
  String get scanToFill => 'Scanner le code-barres';

  @override
  String get suggestFromPhoto => 'Suggérer le nom depuis la photo';

  @override
  String get suggestionApplied =>
      'Rempli à partir de l\'étiquette. Vérifiez avant d\'enregistrer.';

  @override
  String get suggestionFailed => 'Étiquette illisible. Saisissez le nom.';

  @override
  String get scanBarcode => 'Scanner un code-barres';

  @override
  String get pointCamera => 'Visez le code-barres avec l\'appareil photo';

  @override
  String get typeNumberInstead => 'Saisir le numéro';

  @override
  String get typeBarcodeTitle => 'Saisir le code-barres';

  @override
  String get find => 'Chercher';

  @override
  String get flashOn => 'Allumer le flash';

  @override
  String get flashOff => 'Éteindre le flash';

  @override
  String get found => 'Trouvé';

  @override
  String get notFound => 'Introuvable';

  @override
  String get noProductWithBarcode =>
      'Aucun produit n\'a encore ce code-barres.';

  @override
  String inStockCount(int stock, String unit) {
    return '$stock $unit en stock';
  }

  @override
  String get cameraPermissionDenied =>
      'L\'accès à l\'appareil photo est désactivé. Autorisez-le dans les réglages, ou saisissez le numéro.';

  @override
  String get openSettings => 'Ouvrir les réglages';

  @override
  String get cameraUnavailable =>
      'Pas d\'appareil photo ici. Saisissez le numéro.';

  @override
  String get stockCount => 'Inventaire';

  @override
  String countedOf(int total) {
    return 'sur $total comptés';
  }

  @override
  String get justScanned => 'Dernier scan';

  @override
  String expectedQty(int count) {
    return 'Attendu $count';
  }

  @override
  String get oneLess => 'Un de moins';

  @override
  String get oneMore => 'Un de plus';

  @override
  String get differences => 'Écarts';

  @override
  String get allCounted => 'Tout compté';

  @override
  String get noDifferences => 'Aucun écart pour l\'instant.';

  @override
  String get nothingCounted =>
      'Rien de compté. Scannez le premier article du rayon.';

  @override
  String get finishCount => 'Terminer';

  @override
  String get scanNext => 'Scanner';

  @override
  String expectedCounted(int expected, int counted) {
    return 'Attendu $expected · Compté $counted';
  }

  @override
  String get finishCountTitle => 'Terminer l\'inventaire ?';

  @override
  String get finishCountNoDiff => 'Aucun écart. Le stock reste inchangé.';

  @override
  String finishCountBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count produits',
      one: '1 produit',
    );
    return 'Le stock sera corrigé pour $_temp0.';
  }

  @override
  String get commitCount => 'Enregistrer l\'inventaire';

  @override
  String get keepCounting => 'Continuer';

  @override
  String get countSaved => 'Inventaire enregistré.';

  @override
  String get leaveCountTitle => 'Quitter l\'inventaire ?';

  @override
  String get leaveCountBody =>
      'Votre comptage est enregistré sur ce téléphone. Reprenez-le plus tard, ou abandonnez-le.';

  @override
  String get continueLater => 'Reprendre plus tard';

  @override
  String get discardCount => 'Abandonner';

  @override
  String unknownBarcode(String code) {
    return 'Aucun produit n\'a le code-barres $code.';
  }

  @override
  String get everythingCounted => 'Tout est compté.';

  @override
  String get countInProgressBanner =>
      'Inventaire en cours — les mouvements sont en pause.';

  @override
  String get resumeCount => 'Reprendre';

  @override
  String get mostUrgentFirst => 'Les plus urgents d\'abord';

  @override
  String get allStockedUp => 'Tout est en stock';

  @override
  String itemsToRestock(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count articles à réapprovisionner',
      one: '1 article à réapprovisionner',
    );
    return '$_temp0';
  }

  @override
  String get noRestockNeeded => 'Aucun produit à réapprovisionner.';

  @override
  String get belowReorderPoint => 'Sous le seuil de commande';

  @override
  String ofReorder(int point) {
    return 'sur $point';
  }

  @override
  String get recordReceived => 'Enregistrer une réception';

  @override
  String get reorderIdeas => 'Idées de commande';

  @override
  String get reorderIdeasFailed =>
      'Impossible de préparer des suggestions pour l\'instant.';

  @override
  String get syncTitle => 'Synchro';

  @override
  String get youreOffline => 'Vous êtes hors ligne';

  @override
  String get youreOnline => 'Vous êtes en ligne';

  @override
  String get syncing => 'Synchronisation…';

  @override
  String get allSynced => 'Tout est synchronisé';

  @override
  String lastSynced(String time) {
    return 'Dernière synchro $time';
  }

  @override
  String get neverSynced => 'Pas encore synchronisé';

  @override
  String pendingOffline(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count modifications sont en sécurité sur ce téléphone. Elles seront envoyées dès votre retour en ligne.',
      one:
          '1 modification est en sécurité sur ce téléphone. Elle sera envoyée dès votre retour en ligne.',
      zero:
          'Rien en attente. Les nouvelles modifications restent sur ce téléphone.',
    );
    return '$_temp0';
  }

  @override
  String pendingOnline(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modifications attendent d\'être envoyées.',
      one: '1 modification attend d\'être envoyée.',
      zero: 'Toutes vos modifications sont sur le serveur.',
    );
    return '$_temp0';
  }

  @override
  String get trySyncNow => 'Synchroniser maintenant';

  @override
  String get syncNow => 'Synchroniser';

  @override
  String get syncFailed =>
      'La synchro n\'a pas abouti. Elle réessaiera toute seule.';

  @override
  String get syncDone => 'Synchronisation terminée.';

  @override
  String waitingToUpload(int count) {
    return 'En attente d\'envoi · $count';
  }

  @override
  String needsALook(int count) {
    return 'À vérifier · $count';
  }

  @override
  String conflictTitle(String name) {
    return '$name a été modifié sur deux téléphones';
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
    return 'Conservé « $kept » ($keptBy, $keptAt). Remplacé « $lost » ($lostBy, $lostAt).';
  }

  @override
  String get dismiss => 'Ignorer';

  @override
  String pendingEdited(String name) {
    return 'Modifié · $name';
  }

  @override
  String pendingMovement(String action, String name) {
    return '$action · $name';
  }

  @override
  String get demoModeTitle => 'Mode démo';

  @override
  String get demoModeBody =>
      'Cette version n\'a pas de serveur : tout reste sur ce téléphone.';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get language => 'Langue';

  @override
  String get theme => 'Thème';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get themeSystem => 'Système';

  @override
  String get staffAccounts => 'Comptes du personnel';

  @override
  String get roleOwner => 'Propriétaire';

  @override
  String get roleStaff => 'Employé';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get signOutTitle => 'Se déconnecter ?';

  @override
  String get signOutBody =>
      'Les données sont effacées de ce téléphone pour la prochaine personne.';

  @override
  String signOutPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count modifications ne sont pas encore synchronisées et seront perdues.',
      one: '1 modification n\'est pas encore synchronisée et sera perdue.',
    );
    return '$_temp0';
  }

  @override
  String appVersion(String version) {
    return 'Jerd $version';
  }

  @override
  String get addStaff => 'Ajouter un compte';

  @override
  String get staffName => 'Nom';

  @override
  String get role => 'Rôle';

  @override
  String get staffAdded => 'Compte créé.';

  @override
  String get staffRemoved => 'Compte supprimé.';

  @override
  String get removeStaffTitle => 'Supprimer le compte ?';

  @override
  String removeStaffBody(String name) {
    return '$name ne pourra plus se connecter.';
  }

  @override
  String get remove => 'Supprimer';

  @override
  String get ownerOnlyStaff =>
      'Seul le propriétaire peut ajouter ou supprimer des comptes.';

  @override
  String updateAvailable(String version) {
    return 'Mise à jour disponible : $version';
  }

  @override
  String get updateRequired =>
      'Cette version est trop ancienne. Mettez à jour pour continuer à synchroniser.';

  @override
  String get updateNow => 'Mettre à jour';
}
