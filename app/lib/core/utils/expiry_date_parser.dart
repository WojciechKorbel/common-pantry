class ExpiryDateParser {
  ExpiryDateParser._();

  static const Map<String, int> _monthNames = {
    'jan': 1,
    'sty': 1,
    'feb': 2,
    'lut': 2,
    'mar': 3,
    'apr': 4,
    'kwi': 4,
    'may': 5,
    'maj': 5,
    'jun': 6,
    'cze': 6,
    'jul': 7,
    'lip': 7,
    'aug': 8,
    'sie': 8,
    'sep': 9,
    'wrz': 9,
    'oct': 10,
    'paź': 10,
    'paz': 10,
    'nov': 11,
    'lis': 11,
    'dec': 12,
    'gru': 12,
  };

  /// Parses raw OCR text and returns unique, valid candidate expiry dates
  /// sorted chronologically.
  static List<DateTime> extractDates(String rawText, {DateTime? referenceDate}) {
    if (rawText.trim().isEmpty) return const [];

    final now = referenceDate ?? DateTime.now();
    final minYear = now.year - 1;
    final maxYear = now.year + 15;
    final results = <DateTime>{};

    // Normalize common OCR quirks:
    // 1. Replace commas/colons between digits with dots (e.g. "28,08.27" -> "28.08.27")
    // 2. Remove spaces around dots/slashes/hyphens (e.g. "12. 11. 2026" -> "12.11.2026")
    // 3. Normalize space between DD.MM and YY/YYYY (e.g. "28.08 27" -> "28.08.27")
    final normalized = rawText
        .replaceAllMapped(RegExp(r'(?<=\d)[,:](?=\d)'), (_) => '.')
        .replaceAllMapped(RegExp(r'\s*([./-])\s*'), (m) => m.group(1)!)
        .replaceAllMapped(
          RegExp(r'(?<!\d)(\d{1,2}[./-]\d{1,2})\s+(20\d{2}|\d{2})(?!\d)'),
          (m) => '${m.group(1)}.${m.group(2)}',
        );

    // 1. YYYY-MM-DD, YYYY.MM.DD, YYYY/MM/DD
    final ymdRegex = RegExp(r'(?<!\d)(20\d{2})[./-](\d{1,2})[./-](\d{1,2})(?!\d)');
    for (final m in ymdRegex.allMatches(normalized)) {
      final date = _tryBuildDate(
        year: int.parse(m.group(1)!),
        month: int.parse(m.group(2)!),
        day: int.parse(m.group(3)!),
        minYear: minYear,
        maxYear: maxYear,
      );
      if (date != null) results.add(date);
    }

    // 2. DD.MM.YYYY, DD/MM/YYYY, DD-MM-YYYY or DD.MM.YY, DD/MM/YY, DD-MM-YY
    final dmyRegex = RegExp(r'(?<!\d)(\d{1,2})[./-](\d{1,2})[./-](\d{2,4})(?!\d)');
    for (final m in dmyRegex.allMatches(normalized)) {
      final rawYear = int.parse(m.group(3)!);
      final year = rawYear < 100 ? 2000 + rawYear : rawYear;
      final date = _tryBuildDate(
        year: year,
        month: int.parse(m.group(2)!),
        day: int.parse(m.group(1)!),
        minYear: minYear,
        maxYear: maxYear,
      );
      if (date != null) results.add(date);
    }

    // 2b. DD.MMYY or DD.MMYYYY when OCR misses the second dot (e.g. "28.0827")
    final dmyMissingDotRegex = RegExp(r'(?<!\d)(\d{2})[./-](\d{2})(20\d{2}|\d{2})(?!\d)');
    for (final m in dmyMissingDotRegex.allMatches(normalized)) {
      final rawYear = int.parse(m.group(3)!);
      final year = rawYear < 100 ? 2000 + rawYear : rawYear;
      final date = _tryBuildDate(
        year: year,
        month: int.parse(m.group(2)!),
        day: int.parse(m.group(1)!),
        minYear: minYear,
        maxYear: maxYear,
      );
      if (date != null) results.add(date);
    }

    // 3. DD MMM YYYY or DD MMM YY (e.g., "15 NOV 2026", "15 LIS 26")
    final dMonthYRegex = RegExp(
      r'(?<!\d)(\d{1,2})\s+([a-zA-ZąćęłńóśźżĄĆĘŁŃÓŚŹŻ]{3,})\s+(\d{2,4})(?!\d)',
    );
    for (final m in dMonthYRegex.allMatches(rawText)) {
      final monthKey = m.group(2)!.toLowerCase().substring(0, 3);
      final month = _monthNames[monthKey];
      if (month == null) continue;

      final rawYear = int.parse(m.group(3)!);
      final year = rawYear < 100 ? 2000 + rawYear : rawYear;
      final date = _tryBuildDate(
        year: year,
        month: month,
        day: int.parse(m.group(1)!),
        minYear: minYear,
        maxYear: maxYear,
      );
      if (date != null) results.add(date);
    }

    // 4. MM.YYYY or MM/YYYY (e.g., "08/2027" -> defaults to last day of that month)
    if (results.isEmpty) {
      final myRegex = RegExp(r'(?<![\d./-])(\d{1,2})[./-](20\d{2})(?!\d)');
      for (final m in myRegex.allMatches(normalized)) {
        final month = int.parse(m.group(1)!);
        final year = int.parse(m.group(2)!);
        if (month >= 1 && month <= 12 && year >= minYear && year <= maxYear) {
          final lastDay = DateTime(year, month + 1, 0);
          results.add(lastDay);
        }
      }
    }

    final sorted = results.toList()..sort();
    return sorted;
  }

  static DateTime? _tryBuildDate({
    required int year,
    required int month,
    required int day,
    required int minYear,
    required int maxYear,
  }) {
    if (year < minYear || year > maxYear) return null;
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > 31) return null;

    final candidate = DateTime(year, month, day);
    if (candidate.year != year || candidate.month != month || candidate.day != day) {
      return null;
    }
    return candidate;
  }
}
