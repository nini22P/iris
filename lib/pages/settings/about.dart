import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:iris/info.dart';
import 'package:iris/widgets/dialogs/show_release_dialog.dart';
import 'package:iris/utils/get_latest_release.dart';
import 'package:iris/utils/get_localizations.dart';
import 'package:iris/utils/url.dart';
import 'package:package_info_plus/package_info_plus.dart';

class About extends HookWidget {
  const About({super.key});

  static const title = 'About';

  @override
  Widget build(BuildContext context) {
    final t = getLocalizations(context);
    final packageInfo = useState<PackageInfo?>(null);
    final noNewVersion = useState(false);

    useEffect(() {
      void getPackageInfo() async =>
          packageInfo.value = await PackageInfo.fromPlatform();

      getPackageInfo();
      return null;
    }, []);

    return SingleChildScrollView(
      child: Column(
        children: [
          ListTile(
            leading:
                Image.asset('assets/images/logo.png', width: 24, height: 24),
            title: const Text(INFO.title),
            subtitle: Text(t.app_description),
          ),
          ListTile(
            leading: const Icon(Icons.info_rounded),
            title: Text(t.version),
            subtitle: Text(
                packageInfo.value != null ? packageInfo.value!.version : ''),
            onTap: () => launchURL(
                '${INFO.githubUrl}/releases/tag/v${packageInfo.value?.version}'),
          ),
          ListTile(
              leading: const Icon(Icons.update_rounded),
              title: Text(t.check_update),
              subtitle: noNewVersion.value ? Text(t.no_new_version) : null,
              onTap: () async {
                noNewVersion.value = false;
                final release = await getLatestRelease();
                if (release != null && context.mounted) {
                  showReleaseDialog(context, release: release);
                } else {
                  noNewVersion.value = true;
                }
              }),
          ListTile(
            leading: const Icon(Icons.code_rounded),
            title: Text(t.source_code),
            subtitle: const Text(INFO.githubUrl),
            onTap: () => launchURL(INFO.githubUrl),
          ),
          ListTile(
            leading: const Icon(Icons.person_rounded),
            title: Text(t.author),
            subtitle: const Text(INFO.author),
            onTap: () => launchURL(INFO.authorUrl),
          ),
        ],
      ),
    );
  }
}
