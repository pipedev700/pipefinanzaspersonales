import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart';

const srcPath = 'assets/images/logopipefinanzas.jpg';
const outDir = 'assets/images';

bool isBackground(Pixel p) {
  final l = 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
  if (l < 190) return false;
  final mx = math.max(p.r, math.max(p.g, p.b)).toDouble();
  final mn = math.min(p.r, math.min(p.g, p.b)).toDouble();
  final sat = mx == 0 ? 0.0 : (mx - mn) / mx;
  return sat < 0.28;
}

void main() {
  final original = decodeImage(File(srcPath).readAsBytesSync())!;
  final w = original.width, h = original.height;

  // 1) Isolate the mark.
  var minX = w, maxX = -1, minY = h, maxY = -1;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (!isBackground(original.getPixel(x, y))) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }
  final bw = maxX - minX + 1, bh = maxY - minY + 1;
  print('mark bbox: x[$minX..$maxX] y[$minY..$maxY]  ${bw}x$bh');

  // 2) Square canvas with comfortable padding around the mark.
  const padding = 1.10;
  var side = (math.max(bw, bh) * padding).ceil();
  side = math.min(side, math.min(w, h));
  var left = ((minX + maxX) / 2 - side / 2).round();
  var top = ((minY + maxY) / 2 - side / 2).round();
  left = left.clamp(0, w - side);
  top = top.clamp(0, h - side);
  print('square crop: $side px  from ($left, $top)');

  // 3) Flatten the photographic background to one solid brand-neutral cream,
  //    keeping every pixel of the mark exactly as authored.
  final crop = copyCrop(original, x: left, y: top, width: side, height: side);

  var sr = 0, sg = 0, sb = 0, n = 0;
  for (var y = 0; y < side; y++) {
    for (var x = 0; x < side; x++) {
      final p = crop.getPixel(x, y);
      if (isBackground(p)) {
        sr += p.r.toInt();
        sg += p.g.toInt();
        sb += p.b.toInt();
        n++;
      }
    }
  }
  final bgR = (sr / n).round(), bgG = (sg / n).round(), bgB = (sb / n).round();
  print('flat background: rgb($bgR,$bgG,$bgB)  -> #'
      '${bgR.toRadixString(16).padLeft(2, '0')}'
      '${bgG.toRadixString(16).padLeft(2, '0')}'
      '${bgB.toRadixString(16).padLeft(2, '0')}');

  var mr = 0, mg = 0, mb = 0, mn2 = 0;
  for (var y = 0; y < side; y++) {
    for (var x = 0; x < side; x++) {
      final p = crop.getPixel(x, y);
      if (!isBackground(p)) {
        mr += p.r.toInt();
        mg += p.g.toInt();
        mb += p.b.toInt();
        mn2++;
      }
    }
  }
  print('mark average  : rgb(${mr ~/ mn2},${mg ~/ mn2},${mb ~/ mn2})');

  final flat = Image(width: side, height: side, numChannels: 4);
  for (var y = 0; y < side; y++) {
    for (var x = 0; x < side; x++) {
      final p = crop.getPixel(x, y);
      if (isBackground(p)) {
        flat.setPixelRgba(x, y, bgR, bgG, bgB, 0);
      } else {
        flat.setPixelRgba(x, y, p.r.toInt(), p.g.toInt(), p.b.toInt(), 255);
      }
    }
  }

  // 4) Legacy icon: flat cream backdrop + mark, no transparency.
  const legacy = 1024;
  final markOnCream = Image(width: legacy, height: legacy, numChannels: 4);
  fill(markOnCream, color: ColorRgba8(bgR, bgG, bgB, 255));
  final markScaled = copyResize(flat, width: legacy, height: legacy, interpolation: Interpolation.cubic);
  compositeImage(markOnCream, markScaled, blend: BlendMode.alpha);
  File('$outDir/app_icon.png')
    ..createSync(recursive: true)
    ..writeAsBytesSync(encodePng(markOnCream, level: 9));
  print('wrote $outDir/app_icon.png ($legacy x $legacy)');

  // 5) Adaptive foreground: transparent, mark inside the 66% safe zone.
  const fg = 1024;
  const safe = 0.60;
  final inner = (fg * safe).round();
  final fgMark = copyResize(flat, width: inner, height: inner, interpolation: Interpolation.cubic);
  final foreground = Image(width: fg, height: fg, numChannels: 4);
  fill(foreground, color: ColorRgba8(0, 0, 0, 0));
  compositeImage(foreground, fgMark, dstX: (fg - inner) ~/ 2, dstY: (fg - inner) ~/ 2, blend: BlendMode.alpha);
  File('$outDir/app_icon_foreground.png')
    ..createSync(recursive: true)
    ..writeAsBytesSync(encodePng(foreground, level: 9));
  print('wrote $outDir/app_icon_foreground.png ($fg x $fg, mark at ${(safe * 100).toInt()}%)');

  // 6) Full artwork, kept whole, background made transparent, for banners.
  final full = Image(width: original.width, height: original.height, numChannels: 4);
  for (var y = 0; y < original.height; y++) {
    for (var x = 0; x < original.width; x++) {
      final p = original.getPixel(x, y);
      if (isBackground(p)) {
        full.setPixelRgba(x, y, bgR, bgG, bgB, 0);
      } else {
        full.setPixelRgba(x, y, p.r.toInt(), p.g.toInt(), p.b.toInt(), 255);
      }
    }
  }
  final wide = copyResize(full, width: 1200, interpolation: Interpolation.cubic);
  File('$outDir/logo_horizontal.png')
    ..createSync(recursive: true)
    ..writeAsBytesSync(encodePng(wide, level: 9));
  print('wrote $outDir/logo_horizontal.png (${wide.width}x${wide.height})');

  // 7) Tight crop of just the mark, transparent, for the in-app splash.
  const markPad = 6;
  final mLeft = (minX - markPad).clamp(0, w - 1);
  final mTop = (minY - markPad).clamp(0, h - 1);
  final mW = (maxX - minX + 1 + markPad * 2).clamp(1, w - mLeft);
  final mH = (maxY - minY + 1 + markPad * 2).clamp(1, h - mTop);
  final tight = copyCrop(full, x: mLeft, y: mTop, width: mW, height: mH);
  File('$outDir/logo_mark.png')
    ..createSync(recursive: true)
    ..writeAsBytesSync(encodePng(tight, level: 9));
  print('wrote $outDir/logo_mark.png (${tight.width}x${tight.height}, transparent)');
}
