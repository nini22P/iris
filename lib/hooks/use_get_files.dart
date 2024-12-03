import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:iris/models/get_result.dart';

GetResult<T> useGetFiles<T>(
    List<String> path, Future<T> Function(List<String>) function) {
  final isLoading = useState(true);
  final data = useState<T?>(null);
  final error = useState(false);

  useEffect(() {
    isLoading.value = true;
    error.value = false;

    function(path).then((result) {
      data.value = result;
      isLoading.value = false;
    }).catchError((e) {
      error.value = true;
      isLoading.value = false;
    });

    return () {};
  }, [path.join('/')]);

  return GetResult(
    data: data.value,
    isLoading: isLoading.value,
    error: error.value,
  );
}
