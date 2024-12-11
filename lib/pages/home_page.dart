import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:iris/pages/player/iris_player.dart';

class HomePage extends HookWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    useEffect(() {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
      ));
      return null;
    }, []);

    useEffect(() {
      SystemChrome.setSystemUIChangeCallback((value) async {
        if (value) {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
        }
      });
      return () {
        SystemChrome.setSystemUIChangeCallback(null);
      };
    }, []);

    return const Scaffold(
      body: IrisPlayer(),
    );
  }
}
