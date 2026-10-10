import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Result from the DocuHub-style digital signer.
class SignatureResult {
  const SignatureResult({
    required this.base64Png,
    this.signeeName,
    this.signeeTitle,
  });

  final String base64Png;
  final String? signeeName;
  final String? signeeTitle;
}

/// A stroke represented by smoothed points.
class _Stroke {
  _Stroke({required this.points, required this.color, required this.width});

  final List<Offset> points;
  final Color color;
  final double width;
}

/// Modern, DocuHub-inspired signature studio supporting:
/// - Smooth Bezier ink drawing
/// - Digital calligraphic typed signatures
/// - Camera/gallery signature photo capture
/// - Signatory metadata (name & title)
class SignaturePadDialog extends StatefulWidget {
  const SignaturePadDialog({
    this.initialSigneeName,
    this.initialSigneeTitle,
    super.key,
  });

  final String? initialSigneeName;
  final String? initialSigneeTitle;

  static Future<SignatureResult?> show(
    BuildContext context, {
    String? initialSigneeName,
    String? initialSigneeTitle,
  }) =>
      showDialog<SignatureResult>(
        context: context,
        barrierDismissible: false,
        builder: (context) => SignaturePadDialog(
          initialSigneeName: initialSigneeName,
          initialSigneeTitle: initialSigneeTitle,
        ),
      );

  @override
  State<SignaturePadDialog> createState() => _SignaturePadDialogState();
}

class _SignaturePadDialogState extends State<SignaturePadDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Drawing state
  final List<_Stroke> _strokes = [];
  final List<_Stroke> _undoneStrokes = [];
  List<Offset> _currentPoints = [];
  Color _penColor = const Color(0xFF0F172A);
  double _penWidth = 3.5;

  // Type signature state
  late final TextEditingController _nameController;
  late final TextEditingController _titleController;
  int _selectedStyleIndex = 0;

  // Upload/camera state
  Uint8List? _uploadedImageBytes;

  static const List<Color> _penColors = [
    Color(0xFF0F172A), // Slate Black
    Color(0xFF1E3A8A), // Navy Ink
    Color(0xFF2563EB), // Royal Blue
    Color(0xFF7C2D12), // Deep Umber
  ];

  static const List<double> _penWidths = [2.0, 3.5, 5.0];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _nameController = TextEditingController(
      text: widget.initialSigneeName ?? '',
    );
    _titleController = TextEditingController(
      text: widget.initialSigneeTitle ?? 'Authorized Signatory',
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _undoneStrokes.add(_strokes.removeLast());
      });
    }
  }

  void _redo() {
    if (_undoneStrokes.isNotEmpty) {
      setState(() {
        _strokes.add(_undoneStrokes.removeLast());
      });
    }
  }

  void _clearCanvas() {
    setState(() {
      _strokes.clear();
      _undoneStrokes.clear();
      _currentPoints.clear();
      _uploadedImageBytes = null;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 400,
        imageQuality: 85,
      );
      if (photo == null) return;
      final bytes = await photo.readAsBytes();
      setState(() => _uploadedImageBytes = bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load signature image: $e')),
        );
      }
    }
  }

  Future<void> _exportAndSave() async {
    try {
      String? base64Result;
      const canvasWidth = 700;
      const canvasHeight = 220;

      if (_tabController.index == 0) {
        // Draw tab
        if (_strokes.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please draw your signature first.')),
          );
          return;
        }
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        final painter = _SmoothSignaturePainter(
          strokes: _strokes,
          currentStroke: _currentPoints,
          currentColor: _penColor,
          currentWidth: _penWidth,
          showBackground: false,
        );
        painter.paint(canvas, const Size(700, 220));
        final picture = recorder.endRecording();
        final image = await picture.toImage(canvasWidth, canvasHeight);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        picture.dispose();
        if (byteData != null) {
          base64Result = base64Encode(byteData.buffer.asUint8List());
        }
      } else if (_tabController.index == 1) {
        // Type tab
        final name = _nameController.text.trim();
        if (name.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter your signee name.')),
          );
          return;
        }
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        _renderTypedSignature(
          canvas,
          const Size(700, 220),
          name,
          _selectedStyleIndex,
          _penColor,
        );
        final picture = recorder.endRecording();
        final image = await picture.toImage(canvasWidth, canvasHeight);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        picture.dispose();
        if (byteData != null) {
          base64Result = base64Encode(byteData.buffer.asUint8List());
        }
      } else {
        // Upload/Camera tab
        if (_uploadedImageBytes == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Please take a photo or pick a signature.')),
          );
          return;
        }
        base64Result = base64Encode(_uploadedImageBytes!);
      }

      if (base64Result != null && mounted) {
        Navigator.of(context).pop(
          SignatureResult(
            base64Png: base64Result,
            signeeName: _nameController.text.trim().isNotEmpty
                ? _nameController.text.trim()
                : null,
            signeeTitle: _titleController.text.trim().isNotEmpty
                ? _titleController.text.trim()
                : null,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not create signature: $e')),
        );
      }
    }
  }

  void _renderTypedSignature(
    Canvas canvas,
    Size size,
    String name,
    int styleIndex,
    Color color,
  ) {
    // Choose stylish typography styles
    final styles = [
      TextStyle(
        fontFamily: 'serif',
        fontSize: 48,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 1.5,
      ),
      TextStyle(
        fontFamily: 'cursive',
        fontSize: 52,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w500,
        color: color,
        letterSpacing: 2.0,
      ),
      TextStyle(
        fontFamily: 'sans-serif',
        fontSize: 44,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w300,
        color: color,
        letterSpacing: 3.0,
      ),
      TextStyle(
        fontFamily: 'monospace',
        fontSize: 42,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    ];

    final textSpan = TextSpan(text: name, style: styles[styleIndex % styles.length]);
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 40);

    final xCenter = (size.width - textPainter.width) / 2;
    final yCenter = (size.height - textPainter.height) / 2 - 10;
    textPainter.paint(canvas, Offset(xCenter, yCenter));

    // Decorative flourish under signature
    final flourishPaint = Paint()
      ..color = color.withAlpha(180)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final underlinePath = Path();
    final startX = xCenter - 10;
    final endX = xCenter + textPainter.width + 10;
    final lineY = yCenter + textPainter.height + 6;

    underlinePath.moveTo(startX, lineY);
    underlinePath.quadraticBezierTo(
      (startX + endX) / 2,
      lineY + 12,
      endX,
      lineY - 2,
    );
    canvas.drawPath(underlinePath, flourishPaint);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.draw_rounded,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DocuHub Digital Signer',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 19,
                            ),
                          ),
                          Text(
                            'Create a legally binding signature for all your invoices',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Mode Tabs
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor:
                        isDark ? Colors.grey[400] : Colors.grey[600],
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(icon: Icon(Icons.gesture, size: 18), text: 'Draw'),
                      Tab(icon: Icon(Icons.text_fields, size: 18), text: 'Type'),
                      Tab(icon: Icon(Icons.camera_alt, size: 18), text: 'Capture'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Tab Content
                SizedBox(
                  height: 240,
                  child: TabBarView(
                    controller: _tabController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      // TAB 1: DRAW CANVAS
                      _buildDrawTab(isDark),

                      // TAB 2: TYPE SIGNATURE
                      _buildTypeTab(isDark),

                      // TAB 3: UPLOAD / CAMERA
                      _buildCaptureTab(isDark),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Signee Metadata Section
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Signatory Name',
                          hintText: 'e.g. John Doe',
                          prefixIcon: const Icon(Icons.person_outline, size: 20),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Signatory Title',
                          hintText: 'e.g. Authorized Signatory',
                          prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Dialog Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: _exportAndSave,
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Apply Signature'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawTab(bool isDark) {
    return Column(
      children: [
        // Canvas Container
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? Colors.grey[700]! : const Color(0xFFCBD5E1),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  // Signature baseline guide
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 44,
                    child: Row(
                      children: [
                        const Text(
                          '✕',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: const Color(0xFFCBD5E1),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Sign above this line',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Gesture area
                  GestureDetector(
                    onPanStart: (details) {
                      final box = context.findRenderObject() as RenderBox?;
                      if (box == null) return;
                      setState(() {
                        _currentPoints = [details.localPosition];
                        _undoneStrokes.clear();
                      });
                    },
                    onPanUpdate: (details) {
                      setState(() {
                        _currentPoints.add(details.localPosition);
                      });
                    },
                    onPanEnd: (_) {
                      if (_currentPoints.isNotEmpty) {
                        setState(() {
                          _strokes.add(
                            _Stroke(
                              points: List.from(_currentPoints),
                              color: _penColor,
                              width: _penWidth,
                            ),
                          );
                          _currentPoints = [];
                        });
                      }
                    },
                    child: CustomPaint(
                      painter: _SmoothSignaturePainter(
                        strokes: _strokes,
                        currentStroke: _currentPoints,
                        currentColor: _penColor,
                        currentWidth: _penWidth,
                        showBackground: false,
                      ),
                      size: Size.infinite,
                    ),
                  ),

                  // Floating Clear / Undo Controls inside canvas
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Undo',
                          icon: const Icon(Icons.undo_rounded, size: 20),
                          onPressed: _strokes.isEmpty ? null : _undo,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                            foregroundColor: const Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: 'Redo',
                          icon: const Icon(Icons.redo_rounded, size: 20),
                          onPressed: _undoneStrokes.isEmpty ? null : _redo,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                            foregroundColor: const Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: 'Clear',
                          icon: const Icon(Icons.delete_outline_rounded, size: 20),
                          onPressed: (_strokes.isEmpty && _currentPoints.isEmpty)
                              ? null
                              : _clearCanvas,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.red[50],
                            foregroundColor: Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Color & Pen Width Selectors
        Row(
          children: [
            // Pen Colors
            ..._penColors.map((color) {
              final isSelected = _penColor == color;
              return GestureDetector(
                onTap: () => setState(() => _penColor = color),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              );
            }),

            const Spacer(),

            // Pen Thickness
            Row(
              children: _penWidths.map((width) {
                final isSelected = _penWidth == width;
                return GestureDetector(
                  onTap: () => setState(() => _penWidth = width),
                  child: Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary.withAlpha(30)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                      ),
                    ),
                    child: Container(
                      width: 18,
                      height: width,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[600],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeTab(bool isDark) {
    final styles = [
      'Modern Script',
      'Formal Flow',
      'Minimalist Hand',
      'Executive Mono'
    ];
    final previewText = _nameController.text.trim().isEmpty
        ? 'Your Signature'
        : _nameController.text.trim();

    return Column(
      children: [
        // Live Preview Box
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? Colors.grey[700]! : const Color(0xFFCBD5E1),
                width: 1.5,
              ),
            ),
            child: Center(
              child: CustomPaint(
                painter: _TypedSignaturePainter(
                  name: previewText,
                  styleIndex: _selectedStyleIndex,
                  color: _penColor,
                ),
                size: const Size(400, 120),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Style selector chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(styles.length, (index) {
              final isSelected = _selectedStyleIndex == index;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(styles[index], style: const TextStyle(fontSize: 12)),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) setState(() => _selectedStyleIndex = index);
                  },
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildCaptureTab(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : const Color(0xFFCBD5E1),
          width: 1.5,
        ),
      ),
      child: _uploadedImageBytes != null
          ? Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Image.memory(
                      _uploadedImageBytes!,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton.filled(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: () => setState(() => _uploadedImageBytes = null),
                  ),
                ),
              ],
            )
          : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.document_scanner_outlined,
                    size: 40,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Capture paper signature with camera or gallery',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt, size: 18),
                        label: const Text('Take Photo'),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.tonalIcon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library, size: 18),
                        label: const Text('Upload Image'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

/// Painter that renders strokes with Catmull-Rom / Bezier smoothing.
class _SmoothSignaturePainter extends CustomPainter {
  const _SmoothSignaturePainter({
    required this.strokes,
    required this.currentStroke,
    required this.currentColor,
    required this.currentWidth,
    required this.showBackground,
  });

  final List<_Stroke> strokes;
  final List<Offset> currentStroke;
  final Color currentColor;
  final double currentWidth;
  final bool showBackground;

  @override
  void paint(Canvas canvas, Size size) {
    if (showBackground) {
      canvas.drawColor(Colors.white, BlendMode.src);
    }

    // Paint all completed strokes
    for (final stroke in strokes) {
      _paintSmoothedStroke(canvas, stroke.points, stroke.color, stroke.width);
    }

    // Paint actively drawing stroke
    if (currentStroke.isNotEmpty) {
      _paintSmoothedStroke(canvas, currentStroke, currentColor, currentWidth);
    }
  }

  void _paintSmoothedStroke(
    Canvas canvas,
    List<Offset> points,
    Color color,
    double width,
  ) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    if (points.length == 1) {
      canvas.drawCircle(points.first, width / 2, paint..style = PaintingStyle.fill);
      return;
    }

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    if (points.length == 2) {
      path.lineTo(points[1].dx, points[1].dy);
    } else {
      for (var i = 1; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final midX = (p0.dx + p1.dx) / 2;
        final midY = (p0.dy + p1.dy) / 2;
        path.quadraticBezierTo(p0.dx, p0.dy, midX, midY);
      }
      path.lineTo(points.last.dx, points.last.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SmoothSignaturePainter oldDelegate) => true;
}

class _TypedSignaturePainter extends CustomPainter {
  const _TypedSignaturePainter({
    required this.name,
    required this.styleIndex,
    required this.color,
  });

  final String name;
  final int styleIndex;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final styles = [
      TextStyle(
        fontFamily: 'serif',
        fontSize: 36,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 1.5,
      ),
      TextStyle(
        fontFamily: 'cursive',
        fontSize: 40,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w500,
        color: color,
        letterSpacing: 2.0,
      ),
      TextStyle(
        fontFamily: 'sans-serif',
        fontSize: 32,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w300,
        color: color,
        letterSpacing: 2.5,
      ),
      TextStyle(
        fontFamily: 'monospace',
        fontSize: 30,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    ];

    final textSpan = TextSpan(text: name, style: styles[styleIndex % styles.length]);
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 20);

    final x = (size.width - textPainter.width) / 2;
    final y = (size.height - textPainter.height) / 2 - 8;
    textPainter.paint(canvas, Offset(x, y));

    // Underline flourish
    final flourishPaint = Paint()
      ..color = color.withAlpha(160)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final underlinePath = Path();
    final startX = x - 6;
    final endX = x + textPainter.width + 6;
    final lineY = y + textPainter.height + 4;

    underlinePath.moveTo(startX, lineY);
    underlinePath.quadraticBezierTo((startX + endX) / 2, lineY + 10, endX, lineY);
    canvas.drawPath(underlinePath, flourishPaint);
  }

  @override
  bool shouldRepaint(covariant _TypedSignaturePainter oldDelegate) =>
      oldDelegate.name != name ||
      oldDelegate.styleIndex != styleIndex ||
      oldDelegate.color != color;
}
