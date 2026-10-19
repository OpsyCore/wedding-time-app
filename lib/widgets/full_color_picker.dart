import 'package:flutter/material.dart';
import '../core/app_lang.dart';
import '../core/app_theme.dart';

/// پیکر فول دقیقاً شبیه اسکرین‌شات: Grid / Spectrum / Sliders + Opacity + Preview
class FullColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  const FullColorPickerDialog({super.key, required this.initialColor});

  @override
  State<FullColorPickerDialog> createState() => _FullColorPickerDialogState();
}

class _FullColorPickerDialogState extends State<FullColorPickerDialog> with SingleTickerProviderStateMixin {
  late TabController _tab;
  late HSVColor _hsv;
  double _opacity = 1.0;
  late int _r, _g, _b;
  final TextEditingController _hexCtrl = TextEditingController();

  // Grid preset - exactly like first screenshot top row grayscale + rainbow grid
  static const List<Color> _gridColors = [
    // grayscale row
    Color(0xFFFFFFFF), Color(0xFFF2F2F2), Color(0xFFE5E5E5), Color(0xFFCCCCCC), Color(0xFFB3B3B3), Color(0xFF999999), Color(0xFF808080), Color(0xFF666666), Color(0xFF4D4D4D), Color(0xFF333333), Color(0xFF1A1A1A), Color(0xFF000000),
    // main grid - 8 rows x ~10 cols simplified
    Color(0xFF0A3A4A), Color(0xFF1B2A5A), Color(0xFF3A1A6B), Color(0xFF6B1A3A), Color(0xFF8B1A1A), Color(0xFF8B3D1A), Color(0xFF8B6B1A), Color(0xFF6B7B1A), Color(0xFF2F6B1A), Color(0xFF1A6B4A),
    Color(0xFF0F5A6B), Color(0xFF2A3A8B), Color(0xFF5A1A8B), Color(0xFF8B1A5A), Color(0xFFB71C1C), Color(0xFFBF360C), Color(0xFF8D6E00), Color(0xFF7A9A00), Color(0xFF3A8B1A), Color(0xFF1A8B6B),
    Color(0xFF1496A6), Color(0xFF3A4DB3), Color(0xFF7B2AC4), Color(0xFFAB1A6B), Color(0xFFE53935), Color(0xFFEF6C00), Color(0xFFF9A825), Color(0xFF9CCC65), Color(0xFF66BB6A), Color(0xFF26A69A),
    Color(0xFF2AC4D4), Color(0xFF5A6FE8), Color(0xFF9B4DFF), Color(0xFFD42A7A), Color(0xFFFF5252), Color(0xFFFF8A3D), Color(0xFFFFD54F), Color(0xFFB8D98C), Color(0xFF81C784), Color(0xFF4DB6AC),
    Color(0xFF6ED8E8), Color(0xFF8BA0FF), Color(0xFFB98CFF), Color(0xFFE85AA0), Color(0xFFFF8A80), Color(0xFFFFB07A), Color(0xFFFFE57F), Color(0xFFCCDFB0), Color(0xFFA5D6A7), Color(0xFF80CBC4),
    Color(0xFFA0E8F2), Color(0xFFB8C6FF), Color(0xFFD1B8FF), Color(0xFFF0A0C8), Color(0xFFFFB8B0), Color(0xFFFFCCB0), Color(0xFFFFECB3), Color(0xFFDDE8D0), Color(0xFFC8E6C9), Color(0xFFB2DFDB),
    Color(0xFFD0F2F8), Color(0xFFDDE3FF), Color(0xFFE8DDFF), Color(0xFFF8D0E0), Color(0xFFFFD8D0), Color(0xFFFFE0CC), Color(0xFFFFF3C8), Color(0xFFEEF3E8), Color(0xFFE8F5E9), Color(0xFFE0F2F1),
    Color(0xFFE8F8FC), Color(0xFFF0F2FF), Color(0xFFF5EEFF), Color(0xFFFCE8F0), Color(0xFFFFEDE8), Color(0xFFFFF0E0), Color(0xFFFFF8E0), Color(0xFFF5F8F0), Color(0xFFF1F8E9), Color(0xFFE0F7FA),
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    final c = widget.initialColor;
    _hsv = HSVColor.fromColor(c);
    _opacity = c.opacity;
    _r = (c.r * 255).round();
    _g = (c.g * 255).round();
    _b = (c.b * 255).round();
    _hexCtrl.text = '#${_color.hexNoHash.toUpperCase()}';
  }

  @override
  void dispose() {
    _tab.dispose();
    _hexCtrl.dispose();
    super.dispose();
  }

  Color get _color {
    final hsvColor = _hsv.toColor();
    // rebuild with rgb sliders if in sliders tab sync? keep hsv as source for spectrum/grid, rgb for sliders
    // For sliders tab we use _r,_g,_b directly
    if (_tab.index == 2) {
      return Color.fromRGBO(_r, _g, _b, _opacity);
    }
    return hsvColor.withValues(alpha: _opacity);
  }

  void _updateFromColor(Color c) {
    setState(() {
      _hsv = HSVColor.fromColor(c.withValues(alpha: 1));
      _opacity = c.opacity;
      _r = (c.r * 255).round();
      _g = (c.g * 255).round();
      _b = (c.b * 255).round();
      _hexCtrl.text = '#${c.hexNoHash.toUpperCase()}';
    });
  }

  void _updateHex(String v) {
    var hex = v.trim().replaceAll('#', '');
    if (hex.length == 6) {
      final col = int.tryParse(hex, radix: 16);
      if (col != null) {
        final c = Color(0xFF000000 | col);
        setState(() {
          _hsv = HSVColor.fromColor(c);
          _r = (c.r * 255).round();
          _g = (c.g * 255).round();
          _b = (c.b * 255).round();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFa = AppLang.I.isFa;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 620),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
              child: Row(
                children: [
                  Icon(Icons.brush_rounded, color: const Color(0xFF1E88E5), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isFa ? 'انتخاب رنگ' : 'Pick a color',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 20),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Tabs Grid/Spectrum/Sliders
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tab,
                onTap: (_) => setState(() {}),
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6)],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.black87,
                unselectedLabelColor: Colors.black54,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                tabs: const [
                  Tab(text: 'Grid'),
                  Tab(text: 'Spectrum'),
                  Tab(text: 'Sliders'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Tab views
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _buildGridTab(),
                  _buildSpectrumTab(),
                  _buildSlidersTab(),
                ],
              ),
            ),
            // OPACITY row exactly like screenshot
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('OPACITY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.black45, letterSpacing: 0.8)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 28,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // checkerboard
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: SizedBox(
                                  height: 28,
                                  child: CustomPaint(
                                    painter: _CheckerPainter(),
                                    child: Container(),
                                  ),
                                ),
                              ),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  height: 28,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.transparent, _color.withValues(alpha: 1)],
                                    ),
                                  ),
                                ),
                              ),
                              SliderTheme(
                                data: SliderThemeData(
                                  trackHeight: 28,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                                  overlayShape: SliderComponentShape.noOverlay,
                                  activeTrackColor: Colors.transparent,
                                  inactiveTrackColor: Colors.transparent,
                                  thumbColor: Colors.white,
                                ),
                                child: Slider(
                                  value: _opacity,
                                  min: 0,
                                  max: 1,
                                  onChanged: (v) => setState(() => _opacity = v),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('${(_opacity * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 20, thickness: 0.6),
            // Preview + add
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12),
                      boxShadow: [BoxShadow(color: _color.withValues(alpha: 0.35), blurRadius: 10)],
                    ),
                  ),
                  const Spacer(),
                  // + button like screenshot (grey plus)
                  InkWell(
                    onTap: () => Navigator.pop(context, _color),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8E8EC),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_rounded, size: 22, color: Colors.black54),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, _color),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTok.accent(context),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    ),
                    child: Text(isFa ? 'تایید' : 'Done', style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 10, crossAxisSpacing: 4, mainAxisSpacing: 4),
        itemCount: _gridColors.length,
        itemBuilder: (context, i) {
          final c = _gridColors[i];
          final selected = c.value == _color.withValues(alpha: 1).value;
          return GestureDetector(
            onTap: () => _updateFromColor(c),
            child: Container(
              decoration: BoxDecoration(
                color: c,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: selected ? Colors.white : Colors.black12, width: selected ? 2 : 0.6),
                boxShadow: selected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 4)] : null,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSpectrumTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: LayoutBuilder(
        builder: (context, cons) {
          return GestureDetector(
            onPanUpdate: (d) {
              final local = d.localPosition;
              final w = cons.maxWidth;
              final h = 280.0;
              // h is fixed height approx
              final dx = local.dx.clamp(0, w);
              final dy = local.dy.clamp(0, h);
              final hue = (dx / w) * 360;
              // y maps to saturation/value mixed - top is vivid, bottom faded to white?
              // screenshot spectrum: vertical rainbow fading to black on right, white on left
              // approximate: hue from x, saturation from 1 - (y/h)*0.3, value 1
              final sat = (1 - (dy / h) * 0.2).clamp(0.6, 1.0);
              final val = 1.0;
              setState(() {
                _hsv = HSVColor.fromAHSV(1, hue, sat, val);
                final c = _hsv.toColor();
                _r = (c.r * 255).round();
                _g = (c.g * 255).round();
                _b = (c.b * 255).round();
                _hexCtrl.text = '#${c.hexNoHash.toUpperCase()}';
              });
            },
            onTapDown: (d) {
              final local = d.localPosition;
              final w = cons.maxWidth;
              final h = 280.0;
              final dx = local.dx.clamp(0, w);
              final hue = (dx / w) * 360;
              setState(() {
                _hsv = HSVColor.fromAHSV(1, hue, 1, 1);
                final c = _hsv.toColor();
                _r = (c.r * 255).round();
                _g = (c.g * 255).round();
                _b = (c.b * 255).round();
              });
            },
            child: Stack(
              children: [
                // base rainbow spectrum
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: const [
                        Color(0xFFFF0000),
                        Color(0xFFFFEB3B),
                        Color(0xFF00E676),
                        Color(0xFF00BCD4),
                        Color(0xFF3F51B5),
                        Color(0xFFE040FB),
                        Color(0xFFFF0000),
                      ],
                    ),
                  ),
                ),
                // left fade to white + right fade to black overlay like screenshot
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Colors.white.withValues(alpha: 0.85), Colors.transparent, Colors.black.withValues(alpha: 0.95)],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
                // selector dot
                Positioned(
                  left: (_hsv.hue / 360) * cons.maxWidth - 8,
                  top: 140,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black26, width: 1.5),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 6)],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSlidersTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        _sliderRow('R', _r, Colors.red, (v) => setState(() { _r = v; _hsv = HSVColor.fromColor(Color.fromRGBO(_r, _g, _b, 1)); })),
        _sliderRow('G', _g, Colors.green, (v) => setState(() { _g = v; _hsv = HSVColor.fromColor(Color.fromRGBO(_r, _g, _b, 1)); })),
        _sliderRow('B', _b, Colors.blue, (v) => setState(() { _b = v; _hsv = HSVColor.fromColor(Color.fromRGBO(_r, _g, _b, 1)); })),
        const SizedBox(height: 14),
        TextField(
          controller: _hexCtrl,
          decoration: InputDecoration(
            labelText: 'HEX',
            prefixText: '# ',
            filled: true,
            fillColor: const Color(0xFFF5F5F7),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          onChanged: _updateHex,
          onSubmitted: _updateHex,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(width: 28, height: 28, decoration: BoxDecoration(color: Color.fromRGBO(_r, _g, _b, 1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black12))),
            const SizedBox(width: 10),
            Text('RGB($_r, $_g, $_b)', style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ],
    );
  }

  Widget _sliderRow(String label, int value, Color col, ValueChanged<int> onChanged) {
    return Row(
      children: [
        SizedBox(width: 20, child: Text(label, style: TextStyle(color: col, fontWeight: FontWeight.w800))),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 255,
            activeColor: col,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        SizedBox(width: 36, child: Text('$value', textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
      ],
    );
  }
}

extension _Hex on Color {
  String get hexNoHash {
    final r = (this.r * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (this.g * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (this.b * 255).round().toRadixString(16).padLeft(2, '0');
    return '$r$g$b';
  }
}

class _CheckerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const s = 7.0;
    final light = Paint()..color = const Color(0xFFE8E8E8);
    final dark = Paint()..color = const Color(0xFFCFCFCF);
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(20)), light);
    for (double y = 0; y < size.height; y += s) {
      for (double x = 0; x < size.width; x += s) {
        final isDark = ((x / s).floor() + (y / s).floor()) % 2 == 1;
        if (isDark) {
          canvas.drawRect(Rect.fromLTWH(x, y, s, s), dark);
        }
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
