List<String> pathConverter(String path) {
  return path
      .replaceAll('\\', '/')
      .split('/')
      .where((e) => e.isNotEmpty)
      .toList();
}
