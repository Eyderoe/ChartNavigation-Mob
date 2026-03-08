import 'dart:math';
import 'dart:typed_data';

typedef AffineParams = ({List<double> paramsX, List<double> paramsY});
typedef AffinePoint = ({double x, double y});
typedef AffineEval = ({double rmsError, List<double> errors});

/// data row format: [latitude, longitude, x, y]
AffineParams doAffine(Iterable<List<double>> data) {
  final rows = data.toList(growable: false);
  return _doAffineFromRows(rows);
}

AffineParams _doAffineFromRows(List<List<double>> rows) {
  if (rows.length < 3) {
    throw ArgumentError(
      'At least 3 points are required to fit affine parameters.',
    );
  }

  // Build normal equation: (A^T A) p = A^T b
  final ata = List.generate(3, (_) => List<double>.filled(3, 0.0));
  final atbx = List<double>.filled(3, 0.0);
  final atby = List<double>.filled(3, 0.0);

  for (final item in rows) {
    final lat = item[0];
    final lon = item[1];
    final x = item[2];
    final y = item[3];
    ata[0][0] += lon * lon;
    ata[0][1] += lon * lat;
    ata[0][2] += lon;
    ata[1][0] += lat * lon;
    ata[1][1] += lat * lat;
    ata[1][2] += lat;
    ata[2][0] += lon;
    ata[2][1] += lat;
    ata[2][2] += 1.0;

    atbx[0] += lon * x;
    atbx[1] += lat * x;
    atbx[2] += x;
    atby[0] += lon * y;
    atby[1] += lat * y;
    atby[2] += y;
  }

  final px = _solveLinear3x3(ata, atbx);
  final py = _solveLinear3x3(ata, atby);
  return (paramsX: px, paramsY: py);
}

AffineParams _doAffineFromThreeRows(
  List<double> r0,
  List<double> r1,
  List<double> r2,
) {
  final rows = <List<double>>[r0, r1, r2];
  return _doAffineFromRows(rows);
}

class AffineTransformer {
  final Random _random;
  AffineTransformer({Random? random}) : _random = random ?? Random();

  List<List<double>> _data = <List<double>>[];
  List<double> _paramsX = List<double>.filled(3, 0.0);
  List<double> _paramsY = List<double>.filled(3, 0.0);

  bool loadData(List<List<double>> dataList, double threshold) {
    _data = dataList.map((e) => List<double>.from(e)).toList(growable: true);

    if (!_fitAffine()) {
      return false;
    }

    final outlierIndexes = _findAbnormalRansac(_data, threshold);
    outlierIndexes.sort((a, b) => b.compareTo(a));
    for (final idx in outlierIndexes) {
      _data.removeAt(idx);
    }

    return _fitAffine();
  }

  AffinePoint transform(double latitude, double longitude) {
    final x = _paramsX[0] * longitude + _paramsX[1] * latitude + _paramsX[2];
    final y = _paramsY[0] * longitude + _paramsY[1] * latitude + _paramsY[2];
    return (x: x, y: y);
  }

  AffineEval evaluate({bool printResult = false}) {
    if (_data.isEmpty) {
      return (rmsError: 0.0, errors: <double>[]);
    }

    var totalError = 0.0;
    var sumSquaredError = 0.0;
    var maxError = 0.0;
    var minError = double.infinity;
    final errors = <double>[];

    for (final row in _data) {
      final lat = row[0];
      final lon = row[1];
      final xTrue = row[2];
      final yTrue = row[3];

      final xPred = _paramsX[0] * lon + _paramsX[1] * lat + _paramsX[2];
      final yPred = _paramsY[0] * lon + _paramsY[1] * lat + _paramsY[2];
      final dx = xPred - xTrue;
      final dy = yPred - yTrue;
      final error = sqrt(dx * dx + dy * dy);

      errors.add(error);
      totalError += error;
      sumSquaredError += dx * dx + dy * dy;
      if (error > maxError) maxError = error;
      if (error < minError) minError = error;
    }

    final n = _data.length;
    final meanError = totalError / n;
    final rmsError = sqrt(sumSquaredError / n);

    if (printResult) {
      print('Mean error: ${meanError.toStringAsFixed(2)}');
      print('RMS error: ${rmsError.toStringAsFixed(2)}');
      print(
        'error range: (${minError.toStringAsFixed(2)}, ${maxError.toStringAsFixed(2)})',
      );
    }

    return (rmsError: rmsError, errors: errors);
  }

  bool _fitAffine() {
    if (_data.length < 3) {
      return false;
    }

    final params = doAffine(_data);
    _paramsX = params.paramsX;
    _paramsY = params.paramsY;
    return true;
  }

  List<int> _findAbnormalRansac(List<List<double>> values, double threshold) {
    final n = values.length;
    const iterations = 200;
    var maxInnerCount = 0;
    final bestInnerMask = Uint8List(n);
    final currentInnerMask = Uint8List(n);
    final thresholdSq = threshold * threshold;

    for (var i = 0; i < iterations; i++) {
      currentInnerMask.fillRange(0, n, 0);

      final s0 = _random.nextInt(n);
      var s1 = _random.nextInt(n);
      while (s1 == s0) {
        s1 = _random.nextInt(n);
      }
      var s2 = _random.nextInt(n);
      while (s2 == s0 || s2 == s1) {
        s2 = _random.nextInt(n);
      }

      final params = _doAffineFromThreeRows(values[s0], values[s1], values[s2]);

      var currentInnerCount = 0;
      for (var j = 0; j < n; j++) {
        final lat = values[j][0];
        final lon = values[j][1];
        final xTrue = values[j][2];
        final yTrue = values[j][3];

        final xPred =
            params.paramsX[0] * lon +
            params.paramsX[1] * lat +
            params.paramsX[2];
        final yPred =
            params.paramsY[0] * lon +
            params.paramsY[1] * lat +
            params.paramsY[2];

        final dx = xPred - xTrue;
        final dy = yPred - yTrue;
        if (dx * dx + dy * dy < thresholdSq) {
          currentInnerMask[j] = 1;
          currentInnerCount++;
        }
      }

      if (currentInnerCount > maxInnerCount) {
        maxInnerCount = currentInnerCount;
        bestInnerMask.setRange(0, n, currentInnerMask);
      }

      if (maxInnerCount > n * 0.95) {
        break;
      }
    }

    final abnormal = <int>[];
    for (var i = 0; i < n; i++) {
      if (bestInnerMask[i] == 0) {
        abnormal.add(i);
      }
    }
    return abnormal;
  }
}

List<double> _solveLinear3x3(List<List<double>> matrix, List<double> rhs) {
  final a = List.generate(3, (r) => List<double>.from(matrix[r]));
  final b = List<double>.from(rhs);

  for (var col = 0; col < 3; col++) {
    var pivot = col;
    for (var row = col + 1; row < 3; row++) {
      if (a[row][col].abs() > a[pivot][col].abs()) {
        pivot = row;
      }
    }

    if (a[pivot][col].abs() < 1e-12) {
      throw StateError('Singular matrix while solving affine parameters.');
    }

    if (pivot != col) {
      final tmpRow = a[col];
      a[col] = a[pivot];
      a[pivot] = tmpRow;
      final tmpB = b[col];
      b[col] = b[pivot];
      b[pivot] = tmpB;
    }

    final pivotValue = a[col][col];
    for (var c = col; c < 3; c++) {
      a[col][c] /= pivotValue;
    }
    b[col] /= pivotValue;

    for (var row = 0; row < 3; row++) {
      if (row == col) continue;
      final factor = a[row][col];
      for (var c = col; c < 3; c++) {
        a[row][c] -= factor * a[col][c];
      }
      b[row] -= factor * b[col];
    }
  }

  return b;
}
