/// "5 મિનિટ પહેલાં"-style relative time, measured from [now] (default: now).
String timeAgo(DateTime time, {DateTime? now}) {
  final elapsed = (now ?? DateTime.now()).difference(time);
  if (elapsed.inMinutes < 1) return 'હમણાં જ';
  if (elapsed.inHours < 1) return '${elapsed.inMinutes} મિનિટ પહેલાં';
  if (elapsed.inDays < 1) return '${elapsed.inHours} કલાક પહેલાં';
  return '${elapsed.inDays} દિવસ પહેલાં';
}
