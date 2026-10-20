import 'package:flutter/material.dart';
import 'package:livekit_components/livekit_components.dart' as components;
import 'package:provider/provider.dart';

import 'controllers/app_ctrl.dart';
import 'screens/agent_screen.dart';
import 'screens/welcome_screen.dart';
import 'ui/color_pallette.dart' show LKColorPaletteLight, LKColorPaletteDark;
import 'ui/jarvis/arc_reactor.dart' show JarvisPalette;
import 'widgets/app_layout_switcher.dart';
import 'widgets/session_error_banner.dart';

final appCtrl = AppCtrl();

class VoiceAssistantApp extends StatelessWidget {
  const VoiceAssistantApp({super.key});

  ThemeData buildTheme({required bool isLight}) {
    final colorPallete = isLight ? LKColorPaletteLight() : LKColorPaletteDark();

    return ThemeData(
      useMaterial3: true,
      cardColor: colorPallete.bg2,
      scaffoldBackgroundColor: colorPallete.bg1,
      canvasColor: colorPallete.bg1,
      inputDecorationTheme: InputDecorationTheme(
        fillColor: colorPallete.bg2,
        hintStyle: TextStyle(
          color: colorPallete.fg4,
          fontSize: 14,
        ),
      ),
      buttonTheme: ButtonThemeData(
        disabledColor: JarvisPalette.accentDim,
        colorScheme: ColorScheme.dark(
          primary: Colors.white,
          secondary: Colors.white,
          surface: colorPallete.fgAccent,
        ),
      ),
      colorScheme: isLight
          ? ColorScheme.light(
              primary: JarvisPalette.accentDim,
              secondary: JarvisPalette.accentDim,
              surface: Colors.white,
            )
          : ColorScheme.dark(
              primary: JarvisPalette.accent,
              secondary: JarvisPalette.accent,
              surface: JarvisPalette.accent,
            ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext ctx) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: appCtrl),
          ChangeNotifierProvider.value(value: appCtrl.session),
          ChangeNotifierProvider.value(value: appCtrl.roomContext),
        ],
        child: components.SessionContext(
          session: appCtrl.session,
          child: MaterialApp(
            title: 'JORDAN',
            theme: buildTheme(isLight: true),
            darkTheme: buildTheme(isLight: false),
            // The in-helmet display only ships in one skin.
            themeMode: ThemeMode.dark,
            home: Builder(
              builder: (ctx) => Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: 620),
                  child: Stack(
                    children: [
                      Selector<AppCtrl, AppScreenState>(
                        selector: (ctx, appCtx) => appCtx.appScreenState,
                        builder: (ctx, screen, _) => AppLayoutSwitcher(
                          frontBuilder: (ctx) => const WelcomeScreen(),
                          backBuilder: (ctx) => const AgentScreen(),
                          isFront: screen == AppScreenState.welcome,
                        ),
                      ),
                      const SessionErrorBanner(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
