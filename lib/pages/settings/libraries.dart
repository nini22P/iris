import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:iris/oss_licenses.dart';
import 'package:iris/utils/url.dart';

class Libraries extends HookWidget {
  const Libraries({super.key});

  static const title = 'Libraries';

  final dependencies = allDependencies;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: dependencies.length,
      itemBuilder: (context, index) => ListTile(
        leading: const Icon(Icons.code_rounded),
        title: Text(dependencies[index].name),
        subtitle: Text(
          dependencies[index].license ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: () => showModalBottomSheet(
          context: context,
          // isScrollControlled: true,
          enableDrag: true,
          builder: (BuildContext context) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  Text(
                    dependencies[index].name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => launchURL(
                      dependencies[index].homepage != null
                          ? '${dependencies[index].homepage}'
                          : '${dependencies[index].repository}',
                    ),
                    child: Text(
                      dependencies[index].homepage != null
                          ? '${dependencies[index].homepage}'
                          : '${dependencies[index].repository}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(dependencies[index].license ?? ''),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }
}
