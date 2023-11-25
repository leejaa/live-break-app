import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:live_break_app/screens/detail.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

void main() => runApp(const MaterialApp(home: MyApp()));

const String appId = "d83ce79b868144b4b1465f419b8b1c05";
const String channelName = "test";
const String token =
    "007eJxTYPDfk5b3d0nWtO/rvY2zDqvN6pcRPvFPM/CQ4aeJN47Zzc5UYDAxNTFMTUq0MDJPSTKxNDKzNLFMMjBNTUpJtDAwSTRIdS1OTG0IZGT4wfCTgREKQXwWhpLU4hIGBgCuJSC+";

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey webViewKey = GlobalKey();

  int uid = 0; // uid of the local user
  late RtcEngine agoraEngine; // Agora engine instance

  late InAppWebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    // Set up an instance of Agora engine
    if (Platform.isAndroid) {
      setupVideoSDKEngine();
    }
  }

  Future<void> setupVideoSDKEngine() async {
    // retrieve or request camera and microphone permissions
    // await [Permission.microphone, Permission.camera].request();
    await [Permission.camera].request();

    //create an instance of the Agora engine
    agoraEngine = createAgoraRtcEngine();
    await agoraEngine.initialize(const RtcEngineContext(appId: appId));

    await agoraEngine.enableVideo();

    await agoraEngine.startPreview();

    ChannelMediaOptions options = const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        isAudioFilterable: true,
        autoSubscribeAudio: false);

    await agoraEngine.joinChannel(
      token: token,
      channelId: channelName,
      options: options,
      uid: uid,
    );

    // Register the event handler
    agoraEngine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {},
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {},
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      body: SafeArea(
          child: RefreshIndicator(
        onRefresh: () async {
          _webViewController.reload();
        },
        child: InAppWebView(
          key: webViewKey,
          initialUrlRequest:
              URLRequest(url: Uri.parse("https://live-break-web.vercel.app")),
          initialOptions: InAppWebViewGroupOptions(
            crossPlatform: InAppWebViewOptions(
                javaScriptCanOpenWindowsAutomatically: true,
                javaScriptEnabled: true,
                useOnDownloadStart: true,
                useOnLoadResource: true,
                useShouldOverrideUrlLoading: true,
                mediaPlaybackRequiresUserGesture: false,
                allowFileAccessFromFileURLs: true,
                allowUniversalAccessFromFileURLs: true,
                verticalScrollBarEnabled: true,
                userAgent:
                    // 'Mozilla/5.0 (Linux; Android 9; LG-H870 Build/PKQ1.190522.001) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/83.0.4103.106 Mobile Safari/537.36'),
                    'Mozilla/5.0 (Linux; Android 9; LG-H870 Build/PKQ1.190522.001) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/83.0.4103.106 Mobile Safari/537.36 webview'),
            android: AndroidInAppWebViewOptions(
                blockNetworkImage: false,
                blockNetworkLoads: false,
                networkAvailable: true,
                useHybridComposition: true,
                allowContentAccess: true,
                builtInZoomControls: true,
                thirdPartyCookiesEnabled: true,
                allowFileAccess: true,
                supportMultipleWindows: true),
            ios: IOSInAppWebViewOptions(
              allowsInlineMediaPlayback: true,
              allowsBackForwardNavigationGestures: true,
              allowsPictureInPictureMediaPlayback: true,
            ),
          ),
          onWebViewCreated: (controller) {
            controller.addJavaScriptHandler(
                handlerName: 'navigation',
                callback: (args) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context2) => DetailScreen(id: args[0]['id'])),
                  );
                });
            _webViewController = controller;
          },
          androidOnPermissionRequest: (InAppWebViewController controller,
              String origin, List<String> resources) async {
            return PermissionRequestResponse(
                resources: resources,
                action: PermissionRequestResponseAction.GRANT);
          },
        ),
      )),
    ));
  }
}
