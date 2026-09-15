import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/product.dart';
import '../../../data/repositories/products_repo.dart';
import '../../../data/services/ai_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../di/service_locator.dart';
import '../../../infrastructure/app_logger.dart';
import '../../../logic/cubits/auth/auth_cubit.dart';
import '../../../logic/cubits/failure.dart';
import '../../../logic/cubits/products/products_cubit.dart';
import '../../../logic/domain/validators.dart';
import '../../l10n_helpers.dart';
import '../../themes/app_palette.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/my_snackbar.dart';
import '../../widgets/progress_button.dart';
import '../../widgets/ui.dart';
import '../scan/scan_screen.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;
  final String? initialBarcode;

  const ProductFormScreen({super.key, this.product, this.initialBarcode});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  static const units = ['pcs', 'bottles', 'bags', 'boxes', 'packs', 'cans', 'jars', 'kg', 'L'];

  final formKey = GlobalKey<FormState>();
  final repository = getIt<ProductsRepo>();
  late final TextEditingController name;
  late final TextEditingController barcode;
  late final TextEditingController reorder;
  late String unit;
  String? imagePath;
  String? duplicateOf;
  bool suggesting = false;

  bool get editing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    name = TextEditingController(text: p?.name ?? '');
    barcode = TextEditingController(text: p?.barcode ?? widget.initialBarcode ?? '');
    reorder = TextEditingController(text: p?.reorderPoint.toString() ?? '5');
    unit = p?.unit ?? units.first;
    imagePath = p?.imageUrl;
    checkBarcode(barcode.text);
  }

  @override
  void dispose() {
    name.dispose();
    barcode.dispose();
    reorder.dispose();
    super.dispose();
  }

  Future<void> checkBarcode(String value) async {
    final text = value.trim();
    final existing = text.isEmpty ? null : await repository.getByBarcode(text);
    if (!mounted || barcode.text.trim() != text) return;
    setState(() {
      duplicateOf = existing != null && existing.uuid != widget.product?.uuid ? existing.name : null;
    });
  }

  Future<void> scanBarcode() async {
    final code = await ScanScreen.pick(context);
    if (code == null || !mounted) return;
    barcode.text = code;
    await checkBarcode(code);
  }

  Future<void> pickPhoto() async {
    final l10n = context.l10n;
    final source = await showModalBottomSheet<ImageSource?>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (ScanScreen.cameraSupported)
              ListTile(
                leading: const AppIcon(AppIcons.camera),
                title: Text(l10n.takePhoto),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
            ListTile(
              leading: const AppIcon(AppIcons.image),
              title: Text(l10n.chooseFromGallery),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            if (imagePath != null)
              ListTile(
                leading: AppIcon(AppIcons.trash, color: sheetContext.palette.error),
                title: Text(l10n.removePhoto, style: TextStyle(color: sheetContext.palette.error)),
                onTap: () {
                  setState(() => imagePath = null);
                  Navigator.pop(sheetContext);
                },
              ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final picked = await ImagePicker().pickImage(source: source, maxWidth: 1024, imageQuality: 80);
      if (picked == null) return;
      // Keep a copy in app storage; sync uploads it and swaps in the URL.
      final kept = await getIt<StorageService>().keepLocally(picked.path, const Uuid().v4());
      if (mounted) setState(() => imagePath = kept);
    } catch (e, st) {
      AppLogger.error('Picking a photo failed', e, st);
      if (mounted) MySnackBar.error(context, l10n.errorUnknown);
    }
  }

  Future<void> suggestFromPhoto() async {
    final path = imagePath;
    if (path == null || path.startsWith('http')) return;
    final l10n = context.l10n;
    setState(() => suggesting = true);
    try {
      final suggestion = await getIt<AiService>().suggestFromPhoto(path, barcode: barcode.text.trim());
      if (!mounted) return;
      if (suggestion == null) {
        MySnackBar.error(context, l10n.suggestionFailed);
        return;
      }
      name.text = suggestion.name;
      final suggestedUnit = suggestion.unit;
      if (suggestedUnit != null && units.contains(suggestedUnit)) setState(() => unit = suggestedUnit);
      MySnackBar.success(context, l10n.suggestionApplied);
    } catch (e) {
      if (mounted) MySnackBar.error(context, l10n.suggestionFailed);
    } finally {
      if (mounted) setState(() => suggesting = false);
    }
  }

  Future<ReturnResult> save() async {
    final l10n = context.l10n;
    FocusScope.of(context).unfocus();
    if (!formKey.currentState!.validate()) {
      return ReturnResult(state: false, message: l10n.errorValidation);
    }
    await checkBarcode(barcode.text);
    if (duplicateOf != null) {
      return ReturnResult(state: false, message: l10n.errorDuplicateBarcode(duplicateOf!));
    }
    if (!mounted) return const ReturnResult(state: false, message: '');
    final navigator = Navigator.of(context);
    final result = await context.read<ProductsCubit>().saveProduct(
          existing: widget.product,
          name: name.text,
          barcode: barcode.text,
          unit: unit,
          reorderPoint: int.parse(reorder.text.trim()),
          imageUrl: imagePath,
        );
    if (result.ok) navigator.pop(true);
    if (result.failure?.kind == FailureKind.duplicateBarcode && mounted) {
      setState(() => duplicateOf = result.failure!.detail);
    }
    return toReturnResult(l10n, result);
  }

  Future<void> showDeleteDialog() async {
    final l10n = context.l10n;
    final products = context.read<ProductsCubit>();
    final product = widget.product!;
    final result = await showDialog(
      context: context,
      builder: (_) => MyConfirmationDialog(
        dialogType: 'delete',
        title: l10n.deleteProductTitle,
        message: l10n.deleteProductBody(product.name),
        onConfirm: () async => toReturnResult(l10n, await products.deleteProduct(product.uuid)),
      ),
    );
    if (result != null && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.palette;
    final unitOptions = {...units, unit}.toList();
    final isOwner = context.read<AuthCubit>().user?.isOwner ?? false;
    final canSuggest = imagePath != null && !imagePath!.startsWith('http') && getIt<AiService>().isAvailable;

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TopBar(
                leadingIcon: AppIcons.back,
                title: TopBar.titleText(editing ? l10n.editProduct : l10n.addProduct),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PhotoPicker(imagePath: imagePath, onTap: pickPhoto),
                      if (canSuggest) ...[
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: suggesting ? null : suggestFromPhoto,
                          icon: suggesting
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : AppIcon(AppIcons.image, size: 18, color: c.primary),
                          label: Text(l10n.suggestFromPhoto),
                        ),
                      ],
                      const SizedBox(height: 26),
                      TextFormField(
                        controller: name,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(labelText: l10n.productName),
                        validator: (value) => l10n.field(validateProductName(value)),
                      ),
                      const SizedBox(height: 26),
                      TextFormField(
                        controller: barcode,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        textDirection: TextDirection.ltr,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(14)],
                        onChanged: checkBarcode,
                        style: const TextStyle(fontSize: 16, fontFeatures: tabularFigures),
                        decoration: InputDecoration(
                          labelText: l10n.barcode,
                          contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 19, 8, 19),
                          error: duplicateOf == null
                              ? null
                              : Row(
                                  children: [
                                    AppIcon(AppIcons.warning, size: 16, strokeWidth: 2.2, color: c.error),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        l10n.errorDuplicateBarcode(duplicateOf!),
                                        style: TextStyle(fontSize: 13, color: c.error),
                                      ),
                                    ),
                                  ],
                                ),
                          suffixIcon: Padding(
                            padding: const EdgeInsetsDirectional.only(end: 7),
                            child: Tooltip(
                              message: l10n.scanToFill,
                              child: Tappable(
                                onTap: scanBarcode,
                                color: c.primaryContainer,
                                radius: 14,
                                width: 44,
                                height: 44,
                                child: Center(child: AppIcon(AppIcons.scan, size: 22, color: c.primaryDark)),
                              ),
                            ),
                          ),
                          suffixIconConstraints: const BoxConstraints(),
                        ),
                        validator: (value) => l10n.field(validateBarcode(value)),
                      ),
                      const SizedBox(height: 26),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: unit,
                              isExpanded: true,
                              borderRadius: BorderRadius.circular(16),
                              dropdownColor: c.card,
                              icon: AppIcon(AppIcons.chevronDown, size: 20, color: c.textSecondary),
                              style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 16, color: c.text),
                              decoration: InputDecoration(
                                labelText: l10n.unit,
                                contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 17, 12, 17),
                              ),
                              items: [for (final value in unitOptions) DropdownMenuItem(value: value, child: Text(value))],
                              onChanged: (value) => setState(() => unit = value ?? unit),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: reorder,
                              keyboardType: TextInputType.number,
                              textDirection: TextDirection.ltr,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                              style: const TextStyle(fontSize: 16, fontFeatures: tabularFigures),
                              decoration: InputDecoration(labelText: l10n.reorderAt),
                              validator: (value) => l10n.field(validateReorderPoint(value)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          l10n.reorderHelp,
                          style: TextStyle(fontSize: 13, height: 1.4, color: c.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MyProgressButton(label: editing ? l10n.saveChanges : l10n.addProduct, onPressed: save),
                    if (editing && isOwner) ...[
                      const SizedBox(height: 6),
                      Tappable(
                        onTap: showDeleteDialog,
                        height: 52,
                        radius: 20,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppIcon(AppIcons.trash, size: 20, color: c.error),
                            const SizedBox(width: 8),
                            Text(
                              l10n.deleteProduct,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: c.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  final String? imagePath;
  final VoidCallback onTap;

  const _PhotoPicker({required this.imagePath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final l10n = context.l10n;
    final image = productImageProvider(imagePath);
    return Tappable(
      onTap: onTap,
      height: 128,
      radius: 24,
      color: c.surfaceSunken,
      semanticLabel: image == null ? l10n.addPhoto : l10n.changePhoto,
      child: CustomPaint(
        painter: _DashedBorderPainter(color: c.borderStrong, radius: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: image == null ? 64 : 96,
              height: image == null ? 64 : 96,
              alignment: Alignment.center,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: c.primaryContainer,
                borderRadius: BorderRadius.circular(20),
                image: image == null ? null : DecorationImage(image: image, fit: BoxFit.cover),
              ),
              child: image == null ? AppIcon(AppIcons.camera, size: 28, color: c.primaryDark) : null,
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  image == null ? l10n.addPhoto : l10n.changePhoto,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(l10n.cameraOrGallery, style: TextStyle(fontSize: 14, color: c.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  const _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 2.0;
    const dash = 6.0;
    const gap = 4.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    final path = Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
