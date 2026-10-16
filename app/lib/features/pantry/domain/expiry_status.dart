enum ExpiryStatus { expired, soon, fresh }

/// Items expiring within this many days are marked as "soon"
const soonThresholdDays = 3;

/// Whole days from [today] to [expiryDate]. Negative when already expired.
int daysUntil(DateTime expiryDate, DateTime today) {
  final expiry = DateTime.utc(expiryDate.year, expiryDate.month, expiryDate.day);
  final start = DateTime.utc(today.year, today.month, today.day);
  return expiry.difference(start).inDays;
}

ExpiryStatus expiryStatusOf(DateTime expiryDate, DateTime today) {
  final days = daysUntil(expiryDate, today);
  if (days < 0) {
    return ExpiryStatus.expired;
  }
  if (days <= soonThresholdDays) {
    return ExpiryStatus.soon;
  }
  return ExpiryStatus.fresh;
}
