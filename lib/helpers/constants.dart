import 'package:flutter/material.dart';

const appBgColor = Color(0xFFF7F7F7);

final configuration = <String, dynamic>{
  'iceServers': [
    { 'urls': 'stun:stun.l.google.com:19302' },
  ],
  'sdpSemantics': 'unified-plan'
};

final constraints = <String, dynamic>{
  'mandatory': {},
  'optional': [
    {'DtlsSrtpKeyAgreement': true},
  ],
};

final oaConstraints = <String, dynamic>{
  'mandatory': {
    'OfferToReceiveAudio': true,
    'OfferToReceiveVideo': true,
  },
  'optional': [],
};

final mediaConstraints = <String, dynamic>{
  'audio': true,
  'video': {
    'mandatory': {
      'minWidth': '1280',
      'minHeight': '720',
      'minFrameRate': '30',
    },
    'facingMode': 'user', // 'application'
    'optional': [],
  }
};
