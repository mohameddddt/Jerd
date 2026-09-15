import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../data/models/movement.dart';
import '../../../data/models/product.dart';
import '../../../data/repositories/movements_repo.dart';
import '../../../data/repositories/products_repo.dart';
import '../../../di/service_locator.dart';
import '../../l10n_helpers.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_palette.dart';
import '../../themes/status_colors_extensions.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/my_snackbar.dart';
import '../../widgets/ui.dart';
import '../movement/movement_screen.dart';
import '../products/product_detail_screen.dart';
import '../products/product_form_screen.dart';

enum ScanMode {
  /// Resolve the barcode to a product and offer Sold / Received / Add.
  lookup,

  /// Just return the barcode to the caller.
  pick,
}

class _ScanResult {
  final String barcode;
  final Product? product;
  final int stock;

  const _ScanResult({required this.barcode, this.product, this.stock = 0});
}

class ScanScreen extends StatefulWidget {
  final ScanMode mode;

  const ScanScreen({super.key, this.mode = ScanMode.lookup});

  /// The scan-then-record loop: tap Scan → point → tap Sold/Received → Save.
  static Future<void> open(BuildContext context) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScanScreen()));

  /// Returns a scanned or typed barcode, or null.
  static Future<String?> pick(BuildContext context) => Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => const ScanScreen(mode: ScanMode.pick)),
      );

  static bool get cameraSupported => Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
  late final AnimationController line = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);
  final MobileScannerController? camera = ScanScreen.cameraSupported
      ? MobileScannerController(
          detectionSpeed: DetectionSpeed.noDuplicates,
          formats: const [
            BarcodeFormat.ean13,
            BarcodeFormat.ean8,
            BarcodeFormat.upcA,
            BarcodeFormat.upcE,
            BarcodeFormat.code128,
            BarcodeFormat.code39,
            BarcodeFormat.itf2of5,
          ],
        )
      : null;
  _ScanResult? result;
  bool torch = false;
  bool busy = false;

  @override
  void dispose() {
    line.dispose();
    camera?.dispose();
    super.dispose();
  }

  void onDetect(BarcodeCapture capture) {
    final code = capture.barcodes.map((b) => b.rawValue).whereType<String>().firstOrNull;
    if (code == null || busy || result != null) return;
    handle(code);
  }

  Future<void> handle(String code) async {
    final barcode = code.trim();
    if (barcode.isEmpty) return;
    HapticFeedback.mediumImpact();
    if (widget.mode == ScanMode.pick) {
      Navigator.of(context).pop(barcode);
      return;
    }
    busy = true;
    try {
      final product = await getIt<ProductsRepo>().getByBarcode(barcode);
      final stock = product == null ? 0 : await getIt<MovementsRepo>().getStock(product.uuid);
      if (!mounted) return;
      setState(() => result = _ScanResult(barcode: barcode, product: product, stock: stock));
      await camera?.stop();
    } finally {
      busy = false;
    }
  }

  Future<void> resume() async {
    setState(() => result = null);
    await camera?.start();
  }

  Future<void> typeNumber() async {
    final l10n = context.l10n;
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.typeBarcodeTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          textDirection: TextDirection.ltr,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(labelText: l10n.barcode),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(dialogContext, controller.text), child: Text(l10n.find)),
        ],
      ),
    );
    controller.dispose();
    if (code != null && code.trim().isNotEmpty) await handle(code);
  }

  Future<void> record(Product product, MovementReason reason) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => MovementScreen(product: product, initialReason: reason)),
    );
    if (!mounted) return;
    if (saved == true) MySnackBar.success(context, context.l10n.movementRecorded);
    await resume();
  }

  Future<void> openProduct(Product product) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: product.uuid)),
    );
    if (mounted) await resume();
  }

  Future<void> createProduct(String code) async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ProductFormScreen(initialBarcode: code)),
    );
    if (!mounted) return;
    if (created == true) {
      MySnackBar.success(context, context.l10n.productCreated);
      setState(() => result = null);
      await handle(code);
    } else {
      await resume();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const onScan = AppColors.onScanBackground;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.scanBackground,
        body: Stack(
          children: [
            if (camera != null)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.55,
                  child: MobileScanner(
                    controller: camera,
                    onDetect: onDetect,
                    errorBuilder: (context, error) => _CameraError(error: error, onType: typeNumber),
                  ),
                ),
              ),
            SafeArea(
              child: Column(
                children: [
                  SizedBox(
                    height: 64,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          CircleIconButton(
                            icon: AppIcons.close,
                            color: onScan,
                            tooltip: l10n.close,
                            onTap: () => Navigator.of(context).pop(),
                          ),
                          Expanded(
                            child: Text(
                              l10n.scanBarcode,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: onScan),
                            ),
                          ),
                          if (camera != null)
                            CircleIconButton(
                              icon: AppIcons.flash,
                              iconSize: 22,
                              tooltip: torch ? l10n.flashOff : l10n.flashOn,
                              color: torch ? AppColors.scanAccent : onScan,
                              background: onScan.withValues(alpha: 0.12),
                              onTap: () async {
                                await camera!.toggleTorch();
                                setState(() => torch = !torch);
                              },
                            )
                          else
                            const SizedBox(width: 48),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 70),
                  _Viewfinder(line: line, showBars: camera == null),
                  const SizedBox(height: 22),
                  Text(
                    camera == null ? l10n.cameraUnavailable : l10n.pointCamera,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Color(0xFFD9CCC0)),
                  ),
                  const SizedBox(height: 22),
                  Tappable(
                    onTap: typeNumber,
                    height: 48,
                    radius: 24,
                    border: BorderSide(color: onScan.withValues(alpha: 0.35)),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppIcon(AppIcons.hash, size: 20, color: onScan),
                        const SizedBox(width: 8),
                        Text(
                          l10n.typeNumberInstead,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: onScan),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              left: 0,
              right: 0,
              bottom: result == null ? -360 : 0,
              child: result == null
                  ? const SizedBox(height: 1)
                  : _ResultSheet(
                      result: result!,
                      onOpen: openProduct,
                      onRecord: record,
                      onCreate: createProduct,
                      onDismiss: resume,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  final MobileScannerException error;
  final VoidCallback onType;

  const _CameraError({required this.error, required this.onType});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return Container(
      color: AppColors.scanBackground,
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            denied ? l10n.cameraPermissionDenied : l10n.cameraUnavailable,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: AppColors.onScanBackground),
          ),
          if (denied) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: openAppSettings, child: Text(l10n.openSettings)),
          ],
        ],
      ),
    );
  }
}

class _Viewfinder extends StatelessWidget {
  final Animation<double> line;
  final bool showBars;

  const _Viewfinder({required this.line, required this.showBars});

  static const corners =
      '<svg xmlns="http://www.w3.org/2000/svg" width="290" height="190" viewBox="0 0 290 190" fill="none" stroke="#E8875C" stroke-width="5" stroke-linecap="round"><path d="M4 40V20a16 16 0 0 1 16-16h20"/><path d="M250 4h20a16 16 0 0 1 16 16v20"/><path d="M286 150v20a16 16 0 0 1-16 16h-20"/><path d="M40 186H20a16 16 0 0 1-16-16v-20"/></svg>';

  static const bars =
      '<svg xmlns="http://www.w3.org/2000/svg" width="190" height="90" viewBox="0 0 190 90" fill="#FBF4EC"><rect x="0" y="0" width="6" height="90"/><rect x="10" y="0" width="3" height="90"/><rect x="17" y="0" width="8" height="90"/><rect x="29" y="0" width="3" height="90"/><rect x="36" y="0" width="5" height="90"/><rect x="46" y="0" width="3" height="90"/><rect x="53" y="0" width="9" height="90"/><rect x="66" y="0" width="3" height="90"/><rect x="73" y="0" width="5" height="90"/><rect x="82" y="0" width="7" height="90"/><rect x="93" y="0" width="3" height="90"/><rect x="100" y="0" width="6" height="90"/><rect x="110" y="0" width="3" height="90"/><rect x="117" y="0" width="8" height="90"/><rect x="129" y="0" width="4" height="90"/><rect x="137" y="0" width="3" height="90"/><rect x="144" y="0" width="7" height="90"/><rect x="155" y="0" width="3" height="90"/><rect x="162" y="0" width="5" height="90"/><rect x="171" y="0" width="3" height="90"/><rect x="178" y="0" width="7" height="90"/><rect x="188" y="0" width="2" height="90"/></svg>';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 290,
      height: 190,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SvgPicture.string(corners, width: 290, height: 190),
          if (showBars) Opacity(opacity: 0.85, child: SvgPicture.string(bars, width: 190, height: 90)),
          AnimatedBuilder(
            animation: line,
            builder: (context, child) => Positioned(
              left: 20,
              right: 20,
              top: 50 + 88 * Curves.easeInOut.transform(line.value),
              child: child!,
            ),
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.scanAccent,
                borderRadius: BorderRadius.circular(2),
                boxShadow: const [BoxShadow(color: Color(0xCCE8875C), blurRadius: 12)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultSheet extends StatelessWidget {
  final _ScanResult result;
  final ValueChanged<Product> onOpen;
  final void Function(Product, MovementReason) onRecord;
  final ValueChanged<String> onCreate;
  final VoidCallback onDismiss;

  const _ResultSheet({
    required this.result,
    required this.onOpen,
    required this.onRecord,
    required this.onCreate,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final status = StatusColors.of(context);
    final c = context.palette;
    final l10n = context.l10n;
    final product = result.product;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return GestureDetector(
      onVerticalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) > 200) onDismiss();
      },
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 28 + bottomInset),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(color: c.dragHandle, borderRadius: BorderRadius.circular(3)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                AppIcon(
                  product == null ? AppIcons.warning : AppIcons.check,
                  size: 18,
                  strokeWidth: product == null ? 2.2 : 2.6,
                  color: product == null ? status.lowStockText : status.receivedText,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    product == null ? l10n.notFound : l10n.found,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: product == null ? status.lowStockText : status.receivedText,
                    ),
                  ),
                ),
                CircleIconButton(icon: AppIcons.close, size: 36, iconSize: 18, tooltip: l10n.close, onTap: onDismiss),
              ],
            ),
            const SizedBox(height: 8),
            if (product == null) ...[
              Text(
                result.barcode,
                textDirection: TextDirection.ltr,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600, fontFeatures: tabularFigures),
              ),
              const SizedBox(height: 3),
              Text(l10n.noProductWithBarcode, style: TextStyle(fontSize: 14, color: c.textSecondary)),
              const SizedBox(height: 16),
              Tappable(
                onTap: () => onCreate(result.barcode),
                color: c.primary,
                radius: 18,
                height: 60,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppIcon(AppIcons.plus, size: 22, strokeWidth: 2.4, color: c.onPrimary),
                    const SizedBox(width: 8),
                    Text(
                      l10n.addProduct,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: c.onPrimary),
                    ),
                  ],
                ),
              ),
            ] else ...[
              InkWell(
                onTap: () => onOpen(product),
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  children: [
                    ProductAvatar(
                      uuid: product.uuid,
                      name: product.name,
                      imageUrl: product.imageUrl,
                      size: 56,
                      fontSize: 21,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 3),
                          Text(
                            l10n.inStockCount(result.stock, product.unit),
                            style: TextStyle(fontSize: 14, color: c.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    AppIcon(AppIcons.chevronRight, size: 22, color: c.textSecondary, mirrorInRtl: true),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Tappable(
                      onTap: () => onRecord(product, MovementReason.sold),
                      color: status.soldOutContainer,
                      radius: 18,
                      height: 60,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppIcon(AppIcons.minus, size: 22, strokeWidth: 2.4, color: status.onSoldOutContainer),
                          const SizedBox(width: 8),
                          Text(
                            l10n.reasonSold,
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: status.onSoldOutContainer),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Tappable(
                      onTap: () => onRecord(product, MovementReason.received),
                      color: status.received,
                      radius: 18,
                      height: 60,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppIcon(AppIcons.plus, size: 22, strokeWidth: 2.4, color: onReceivedFill(context)),
                          const SizedBox(width: 8),
                          Text(
                            l10n.reasonReceived,
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: onReceivedFill(context)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
