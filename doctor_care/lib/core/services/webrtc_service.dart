import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'supabase_service.dart';

class WebRTCService {
  final _client = SupabaseService.client;

  RTCVideoRenderer localRenderer = RTCVideoRenderer();
  RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  MediaStream? _localStream;
  RTCPeerConnection? _peerConnection;
  StreamSubscription<List<Map<String, dynamic>>>? _sessionSubscription;

  bool isInitialized = false;
  final List<RTCIceCandidate> _candidateBuffer = [];
  final Set<String> _processedCandidates = {};
  final List<Map<String, dynamic>> _myCandidates = [];

  StreamSubscription<List<Map<String, dynamic>>>? _candidateSubscription;

  /// Request runtime permissions for Camera and Microphone
  static Future<bool> requestCallPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    if (!cameraStatus.isGranted || !micStatus.isGranted) {
      debugPrint('Call permissions denied. Camera: $cameraStatus, Mic: $micStatus');
      return false;
    }
    return true;
  }

  Function(MediaStream stream)? onRemoteStream;

  /// Initialize video renderers and local media stream
  Future<bool> initialize() async {
    try {
      final granted = await requestCallPermissions();
      if (!granted) return false;

      await localRenderer.initialize();
      await remoteRenderer.initialize();

      final mediaConstraints = {
        'audio': true,
        'video': {
          'facingMode': 'user',
          'width': {'ideal': 640},
          'height': {'ideal': 480},
        }
      };

      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      localRenderer.srcObject = _localStream;

      try {
        Helper.setSpeakerphoneOn(true);
      } catch (e) {
        debugPrint('Error setting speakerphone: $e');
      }

      final configuration = {
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
          {'urls': 'stun:stun1.l.google.com:19302'},
          {
            'urls': 'turn:openrelay.metered.ca:80',
            'username': 'openrelayproject',
            'credential': 'openrelayproject',
          },
          {
            'urls': 'turn:openrelay.metered.ca:443',
            'username': 'openrelayproject',
            'credential': 'openrelayproject',
          },
        ],
        'sdpSemantics': 'unified-plan',
      };

      _peerConnection = await createPeerConnection(configuration);

      _localStream?.getTracks().forEach((track) {
        _peerConnection?.addTrack(track, _localStream!);
      });

      _peerConnection?.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty) {
          remoteRenderer.srcObject = event.streams[0];
          onRemoteStream?.call(event.streams[0]);
        }
      };

      isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Error initializing WebRTCService: $e');
      return false;
    }
  }

  Future<void> _addCandidateOrBuffer(RTCIceCandidate candidate) async {
    if (candidate.candidate == null || _processedCandidates.contains(candidate.candidate)) return;
    _processedCandidates.add(candidate.candidate!);

    final remoteDesc = await _peerConnection?.getRemoteDescription();
    if (remoteDesc == null) {
      _candidateBuffer.add(candidate);
    } else {
      await _peerConnection?.addCandidate(candidate);
    }
  }

  Future<void> _drainCandidateBuffer() async {
    while (_candidateBuffer.isNotEmpty) {
      final cand = _candidateBuffer.removeAt(0);
      await _peerConnection?.addCandidate(cand);
    }
  }

  /// Initiate call session as Caller (Doctor)
  Future<void> startCall(String sessionId) async {
    if (_peerConnection == null) return;

    // Send ICE Candidates as individual rows to call_candidates & update call_sessions
    _peerConnection?.onIceCandidate = (candidate) async {
      if (candidate.candidate != null) {
        _myCandidates.add(candidate.toMap());
        try {
          await _client.from('call_candidates').insert({
            'session_id': sessionId,
            'sender': 'doctor',
            'candidate': candidate.toMap(),
          });

          final res = await _client.from('call_sessions').select('ice_candidates').eq('id', sessionId).maybeSingle();
          Map<String, dynamic> existing = {};
          if (res != null && res['ice_candidates'] != null) {
            existing = Map<String, dynamic>.from(res['ice_candidates']);
          }
          existing['doctor_list'] = _myCandidates;
          existing['doctor'] = candidate.toMap();

          await _client.from('call_sessions').update({
            'ice_candidates': existing,
          }).eq('id', sessionId);
        } catch (e) {
          debugPrint('Error pushing candidate: $e');
        }
      }
    };

    // Create SDP Offer
    final offer = await _peerConnection?.createOffer();
    if (offer != null) {
      await _peerConnection?.setLocalDescription(offer);
      await _client.from('call_sessions').update({
        'offer_sdp': offer.toMap(),
      }).eq('id', sessionId);
    }

    // 1. Listen for patient's candidates in call_candidates table
    _candidateSubscription = _client
        .from('call_candidates')
        .stream(primaryKey: ['id'])
        .eq('session_id', sessionId)
        .listen((rows) {
          for (final row in rows) {
            if (row['sender'] == 'patient') {
              final candMap = Map<String, dynamic>.from(row['candidate']);
              final candidate = RTCIceCandidate(
                candMap['candidate'],
                candMap['sdpMid'],
                candMap['sdpMLineIndex'],
              );
              _addCandidateOrBuffer(candidate);
            }
          }
        });

    // 2. Listen for SDP Answer and fallback patient ICE candidates
    _sessionSubscription = _client
        .from('call_sessions')
        .stream(primaryKey: ['id'])
        .eq('id', sessionId)
        .listen((data) async {
          if (data.isNotEmpty) {
            final session = data.last;
            final answerMap = session['answer_sdp'];
            final currentRemote = await _peerConnection?.getRemoteDescription();
            if (answerMap != null && currentRemote == null) {
              final answer = Map<String, dynamic>.from(answerMap);
              final description = RTCSessionDescription(answer['sdp'], answer['type']);
              await _peerConnection?.setRemoteDescription(description);
              await _drainCandidateBuffer();
            }

            final candidates = session['ice_candidates'];
            if (candidates != null) {
              final patList = candidates['patient_list'] as List<dynamic>?;
              if (patList != null && patList.isNotEmpty) {
                for (final item in patList) {
                  final map = Map<String, dynamic>.from(item);
                  final candidate = RTCIceCandidate(
                    map['candidate'],
                    map['sdpMid'],
                    map['sdpMLineIndex'],
                  );
                  await _addCandidateOrBuffer(candidate);
                }
              } else if (candidates['patient'] != null) {
                final patCandidateMap = Map<String, dynamic>.from(candidates['patient']);
                final candidate = RTCIceCandidate(
                  patCandidateMap['candidate'],
                  patCandidateMap['sdpMid'],
                  patCandidateMap['sdpMLineIndex'],
                );
                await _addCandidateOrBuffer(candidate);
              }
            }
          }
        });
  }

  /// Toggle microphone state
  void toggleMute(bool isMuted) {
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = !isMuted;
    });
  }

  /// Toggle video camera state
  void toggleVideo(bool isVideoOff) {
    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = !isVideoOff;
    });
  }

  /// Toggle speakerphone state
  void toggleSpeaker(bool isSpeakerOn) {
    try {
      Helper.setSpeakerphoneOn(isSpeakerOn);
    } catch (e) {
      debugPrint('Speaker toggle error: $e');
    }
  }

  /// Dispose WebRTC resources
  Future<void> dispose() async {
    _candidateSubscription?.cancel();
    _sessionSubscription?.cancel();
    _localStream?.getTracks().forEach((track) => track.stop());
    await _localStream?.dispose();
    await _peerConnection?.close();
    await localRenderer.dispose();
    await remoteRenderer.dispose();
  }
}
