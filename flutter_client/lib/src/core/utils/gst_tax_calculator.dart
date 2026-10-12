class GstTaxLine {
  const GstTaxLine({
    required this.label,
    required this.rate,
    required this.amount,
  });

  final String label;
  final double rate;
  final double amount;
}

class GstTaxResult {
  const GstTaxResult({
    required this.taxLines,
    required this.totalTaxAmount,
    required this.isRcm,
    required this.isInterState,
    this.rcmNote,
  });

  final List<GstTaxLine> taxLines;
  final double totalTaxAmount;
  final bool isRcm;
  final bool isInterState;
  final String? rcmNote;
}

class GstTaxCalculator {
  GstTaxCalculator._();

  static GstTaxResult calculate({
    required double taxableAmount,
    required double taxRate,
    String taxLabel = 'GST',
    String taxType = 'GST',
    bool isRcm = false,
    String supplierPlaceOfSupply = '',
    String clientPlaceOfSupply = '',
  }) {
    if (isRcm) {
      return const GstTaxResult(
        taxLines: [],
        totalTaxAmount: 0.0,
        isRcm: true,
        isInterState: false,
        rcmNote: 'Tax payable by recipient under Reverse Charge (0.00)',
      );
    }

    if (taxRate <= 0 || taxableAmount <= 0) {
      return const GstTaxResult(
        taxLines: [],
        totalTaxAmount: 0.0,
        isRcm: false,
        isInterState: false,
      );
    }

    final totalTax = taxableAmount * (taxRate / 100);
    final isGst = taxType.toUpperCase().contains('GST') ||
        taxLabel.toUpperCase().contains('GST');

    if (!isGst) {
      return GstTaxResult(
        taxLines: [
          GstTaxLine(
            label: '$taxLabel (${_formatRate(taxRate)}%)',
            rate: taxRate,
            amount: totalTax,
          ),
        ],
        totalTaxAmount: totalTax,
        isRcm: false,
        isInterState: false,
      );
    }

    final supState = _cleanState(supplierPlaceOfSupply);
    final cliState = _cleanState(clientPlaceOfSupply);
    final isInterState =
        supState.isNotEmpty && cliState.isNotEmpty && supState != cliState;

    if (isInterState) {
      return GstTaxResult(
        taxLines: [
          GstTaxLine(
            label: 'IGST (${_formatRate(taxRate)}%)',
            rate: taxRate,
            amount: totalTax,
          ),
        ],
        totalTaxAmount: totalTax,
        isRcm: false,
        isInterState: true,
      );
    } else {
      final halfRate = taxRate / 2;
      final halfAmount = totalTax / 2;
      return GstTaxResult(
        taxLines: [
          GstTaxLine(
            label: 'CGST (${_formatRate(halfRate)}%)',
            rate: halfRate,
            amount: halfAmount,
          ),
          GstTaxLine(
            label: 'SGST (${_formatRate(halfRate)}%)',
            rate: halfRate,
            amount: halfAmount,
          ),
        ],
        totalTaxAmount: totalTax,
        isRcm: false,
        isInterState: false,
      );
    }
  }

  static String _cleanState(String raw) {
    if (raw.trim().isEmpty) return '';
    var s = raw.trim().toLowerCase();
    s = s.replaceAll(RegExp(r'^\d+\s*[-:]*\s*'), '');
    return s.trim();
  }

  static String _formatRate(double rate) {
    return rate % 1 == 0 ? rate.toInt().toString() : rate.toStringAsFixed(1);
  }
}
