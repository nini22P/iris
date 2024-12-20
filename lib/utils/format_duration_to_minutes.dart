String formatDurationToMinutes(Duration duration) {
  int totalMinutes = duration.inHours * 60 + duration.inMinutes.remainder(60);
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  String twoDigitMinutes = twoDigits(totalMinutes);
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  return "$twoDigitMinutes:$twoDigitSeconds";
}
