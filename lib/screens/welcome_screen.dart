import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' as sdk;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart' show launchUrl;
import '../controllers/app_ctrl.dart' as ctrl;
import '../ui/jarvis/arc_reactor.dart';
import '../ui/jarvis/hud_overlay.dart';
import '../widgets/agent_status_indicator.dart';
import '../widgets/button.dart' as buttons;

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext ctx) => Material(
        child: Stack(
          children: [
            const Positioned.fill(child: HudOverlay()),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 22,
                  children: [
                    const ArcReactor(size: 110),
                    const Column(
                      spacing: 8,
                      children: [
                        Text(
                          'JORDAN',
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 6,
                            color: JarvisPalette.accent,
                          ),
                        ),
                        Text(
                          'MK VII · all systems online',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            letterSpacing: 2,
                            color: JarvisPalette.accent,
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'Awaiting your command.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Color(0xFFB2B2B2)),
                    ),
                    // Agent status indicator
                    const AgentStatusIndicator(),
                    Consumer2<ctrl.AppCtrl, sdk.Session>(
                      builder: (ctx, appCtrl, session, child) {
                        final isProgressing =
                            appCtrl.isSessionStarting || session.connectionState != sdk.ConnectionState.disconnected;
                        return buttons.Button(
                          text: isProgressing ? 'Linking' : 'Initialize',
                          isProgressing: isProgressing,
                          onPressed: () => appCtrl.connect(),
                        );
                      },
                    ),
                    Opacity(
                      opacity: 0.55,
                      child: GestureDetector(
                        onTap: () async {
                          await launchUrl(Uri.parse('https://docs.livekit.io/agents/start/voice-ai/'));
                        },
                        child: const Text(
                          'Powered by LiveKit Agents',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: JarvisPalette.accentDim,
                            decoration: TextDecoration.underline,
                            decorationColor: JarvisPalette.accentDim,
                            decorationThickness: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}
