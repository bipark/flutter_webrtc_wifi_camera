import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io/socket_io.dart';
import 'package:bonsoir/bonsoir.dart';

import '../helpers/constants.dart';

class CameraView extends StatefulWidget {
  const CameraView({Key? key}) : super(key: key);

  @override
  createState()=>CameraViewState();
}

class CameraViewState extends State<CameraView> {
  BonsoirService bonsoir = BonsoirService(name: UniqueKey().toString(), type: "_dartobservatory._tcp", port: 4000);
  BonsoirBroadcast? _broadcast;

  final _localRenderer = RTCVideoRenderer();
  RTCPeerConnection? _localPc;
  MediaStream? _localStream;

  Server? _socketServer;
  Socket? _socket;

  //--------------------------------------------------------------------------//
  @override
  void initState() {
    super.initState();
    _init();
  }

  //--------------------------------------------------------------------------//
  @override
  void dispose() async {
    await _broadcast!.stop();
    super.dispose();
  }

  //--------------------------------------------------------------------------//
  void update() {
    if (mounted) setState(() {});
  }

  //--------------------------------------------------------------------------//
  Future<void> _init() async {
    await _makeWebRTC();
    await _startBroadCast();
    await _startSocketHandler();
  }

  //--------------------------------------------------------------------------//
  Future<void> _startBroadCast() async {
    _broadcast = BonsoirBroadcast(service: bonsoir);
    if (_broadcast != null) {
      await _broadcast!.ready;
      await _broadcast!.start();
    }
  }

  //--------------------------------------------------------------------------//
  Future<void> _startSocketHandler() async {
    _socketServer = Server();
    _socketServer!.on('connection', (client) async {
      _socket = client;
      if (_socket != null) {
        _makeOffer();
      }

      _socket!.on('msg', (data) {
        final msg = jsonDecode(data);
        if (msg["command"] == "signal") {
          socketDataHandler(data);
        }
      });
    });
    _socketServer!.listen(4001);
  }

  //--------------------------------------------------------------------------//
  Future<void> _makeOffer() async {
    RTCSessionDescription desc = await _localPc!.createOffer(oaConstraints);
    await _localPc!.setLocalDescription(desc);
    _sendSocket("signal", "offer", desc.sdp);
  }

  //--------------------------------------------------------------------------//
  Future<void> _makeWebRTC() async {
    await _localRenderer.initialize();

    _localPc = await createPeerConnection(configuration, constraints);
    _localPc!.onIceConnectionState = (RTCIceConnectionState state){
      switch (state) {
        case RTCIceConnectionState.RTCIceConnectionStateFailed:
          _localPc!.restartIce();
          return;
        default:
          return;
      }
    };
    _localPc!.onConnectionState = (RTCPeerConnectionState state) async {
      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          update();
          break;
        default:
          return;
      }
    };
    _localPc!.onIceCandidate = (RTCIceCandidate candidate) async {
      if (candidate != null) {
        await Future.delayed(const Duration(milliseconds: 1000), () {
          _sendSocket("signal", "candidate", {
            'sdpMLineIndex': candidate.sdpMLineIndex,
            'sdpMid': candidate.sdpMid,
            'candidate': candidate.candidate,
          });
        });
      }
    };

    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    _localRenderer.srcObject = _localStream;
    _localStream!.getTracks().forEach((track) {
      _localPc!.addTrack(track, _localStream!);
    });

    update();
  }

  //--------------------------------------------------------------------------//
  void _sendSocket(command, event, data) {
    var request = Map();
    request["command"] = command;
    request["type"] = event;
    request["data"] = data;
    if (_socket != null) {
      _socket!.emit("msg", jsonEncode(request).toString());
    }
  }

  //--------------------------------------------------------------------------//
  void socketDataHandler(String data) async {
    final msg = jsonDecode(data);

    if (msg["type"] == "offer") {
    } else if (msg["type"] == "answer") {
      try {
        if (_localPc != null) {
          await _localPc!.setRemoteDescription(RTCSessionDescription(msg["data"], msg["type"]));
        }
      } catch (e) {
        print(e);
      }
    } else if (msg["type"] == "candidate") {
      final can1 = msg["data"];
      RTCIceCandidate candidate = RTCIceCandidate(can1["candidate"], can1["sdpMid"], can1["sdpMLineIndex"]);
      try {
        if (_localPc != null) await _localPc!.addCandidate(candidate);
      } catch (e) {
        print(e);
      }
    }
  }


  //--------------------------------------------------------------------------//
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          RTCVideoView(_localRenderer),
        ],
      ),
    );
  }

}
