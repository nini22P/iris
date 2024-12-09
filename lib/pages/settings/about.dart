import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:iris/info.dart';
import 'package:iris/utils/url.dart';
import 'package:package_info_plus/package_info_plus.dart';

class About extends HookWidget {
  const About({super.key});

  static const title = 'About';

  @override
  Widget build(BuildContext context) {
    final packageInfo = useState<PackageInfo?>(null);

    useEffect(() {
      void getPackageInfo() async =>
          packageInfo.value = await PackageInfo.fromPlatform();

      getPackageInfo();
      return null;
    }, []);

    return Column(
      children: [
        const ListTile(
          leading: Icon(null),
          title: Text(INFO.title),
          subtitle: Text(INFO.description),
        ),
        ListTile(
          leading: const Icon(Icons.info_rounded),
          title: const Text('Version'),
          subtitle:
              Text(packageInfo.value != null ? packageInfo.value!.version : ''),
        ),
        ListTile(
          leading: const Icon(Icons.code_rounded),
          title: const Text('Source Code'),
          subtitle: const Text(INFO.githubUrl),
          onTap: () => launchURL(INFO.githubUrl),
        ),
        ListTile(
          leading: const Icon(Icons.person_rounded),
          title: const Text('Author'),
          subtitle: const Text(INFO.author),
          onTap: () => launchURL(INFO.authorUrl),
        ),
      ],
    );
  }
}
