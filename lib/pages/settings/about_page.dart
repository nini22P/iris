import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:iris/info.dart';
import 'package:iris/utils/url.dart';
import 'package:iris/widgets/title_bar.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutPage extends HookWidget {
  const AboutPage({super.key});

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

    return Scaffold(
      appBar: const TitleBar(title: title),
      body: Column(
        children: [
          const ListTile(
            leading: Icon(null),
            title: Text(INFO.title),
            subtitle: Text(INFO.description),
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Version'),
            subtitle: Text(
                packageInfo.value != null ? packageInfo.value!.version : ''),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Source Code'),
            subtitle: const Text(INFO.githubUrl),
            onTap: () => launchURL(INFO.githubUrl),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Libraries'),
            onTap: () => Navigator.of(context).pushNamed('/settings/libraries'),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Author'),
            subtitle: const Text(INFO.author),
            onTap: () => launchURL(INFO.authorUrl),
          ),
        ],
      ),
    );
  }
}
