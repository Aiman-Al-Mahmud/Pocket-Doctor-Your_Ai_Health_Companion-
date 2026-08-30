import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../../core/services/call_ringtone_service.dart';
import '../../../core/services/webrtc_service.dart';
import '../../../data/repositories/call_repository.dart';

class PatientCallScreen extends StatefulWidget {
  final String sessionId;
  final String appointmentId;
  final String doctorName;

  const PatientCallScreen({
    super.key,
    required this.sessionId,
    required this.appointmentId,
    this.doctorName = 'Attending Physician',
  });

  @override
  State<PatientCallScreen> createState() => _PatientCallScreenState();
}

class _PatientCallScreenState extends State<PatientCallScreen> {
  final CallRepository _callRepository = CallRepository();
  final WebRTCService _webrtcService = WebRTCService();
  StreamSubscription<CallSessionModel?>? _sessionSubscription;

  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isSpeakerOn = true;
  String _callStatus = 'active';

  Timer? _timer;
  int _secondsElapsed = 0;

  @override
  void initState() {
    super.initState();
    CallRingtoneService.stopRingtone();
    _startCallTimer();
    _listenToSession();
    _initWebRTC();
  }

  Future<void> _initWebRTC() async {
    _webrtcService.onRemoteStream = (stream) {
      if (mounted) setState(() {});
    };
    final success = await _webrtcService.initialize();
    if (success) {
      await _webrtcService.joinCall(widget.sessionId);
      if (mounted) setState(() {});
    }
  }

  void _listenToSession() {
    _sessionSubscription = _callRepository
        .streamCallSession(widget.sessionId)
        .listen((session) {
      if (session != null && mounted) {
        setState(() {
          _callStatus = session.status;
        });

        if (session.status == 'ended' || session.status == 'declined') {
          _timer?.cancel();
          CallRingtoneService.stopRingtone();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Call session ended by doctor.'),
                backgroundColor: Colors.blueGrey,
              ),
            );
            Navigator.of(context).pop();
          }
        }
      }
    });
  }

  void _startCallTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  String _formatDuration(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  Future<void> _endCall() async {
    _timer?.cancel();
    await CallRingtoneService.stopRingtone();
    await _callRepository.updateCallStatus(widget.sessionId, 'ended');
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    _timer?.cancel();
    CallRingtoneService.stopRingtone();
    _webrtcService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Stack(
          children: [
            // Remote Video Stream (Doctor Video Feed)
            Positioned.fill(
              child: Container(
                color: const Color(0xFF1E293B),
                child: _webrtcService.remoteRenderer.srcObject != null
                    ? RTCVideoView(
                        _webrtcService.remoteRenderer,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF0D9488).withValues(alpha: 0.2),
                                border: Border.all(color: const Color(0xFF0D9488), width: 2),
                              ),
                              child: const Icon(
                                Icons.medical_services_rounded,
                                size: 60,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.doctorName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.greenAccent,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Live Telehealth • ${_formatDuration(_secondsElapsed)}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),

            // Patient Self Camera Inset (Top Right)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                width: 110,
                height: 150,
                decoration: BoxDecoration(
                  color: const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _isVideoOff
                      ? Container(
                          color: Colors.black87,
                          child: const Center(
                            child: Icon(Icons.videocam_off, color: Colors.white54, size: 28),
                          ),
                        )
                      : (_webrtcService.localRenderer.srcObject != null
                          ? RTCVideoView(
                              _webrtcService.localRenderer,
                              mirror: true,
                              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                            )
                          : Container(
                              color: const Color(0xFF0F172A),
                              child: const Center(
                                child: Icon(Icons.person, color: Color(0xFF0D9488), size: 48),
                              ),
                            )),
                ),
              ),
            ),

            // Top Bar Back Action
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
            ),

            // Bottom Floating Controls
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Mic Button
                    IconButton(
                      onPressed: () {
                        setState(() => _isMuted = !_isMuted);
                        _webrtcService.toggleMute(_isMuted);
                      },
                      icon: Icon(
                        _isMuted ? Icons.mic_off : Icons.mic,
                        color: _isMuted ? Colors.redAccent : Colors.white,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: _isMuted ? Colors.red.withValues(alpha: 0.2) : Colors.white10,
                      ),
                    ),
                    // Video Toggle
                    IconButton(
                      onPressed: () {
                        setState(() => _isVideoOff = !_isVideoOff);
                        _webrtcService.toggleVideo(_isVideoOff);
                      },
                      icon: Icon(
                        _isVideoOff ? Icons.videocam_off : Icons.videocam,
                        color: _isVideoOff ? Colors.redAccent : Colors.white,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: _isVideoOff ? Colors.red.withValues(alpha: 0.2) : Colors.white10,
                      ),
                    ),
                    // Speaker Button
                    IconButton(
                      onPressed: () {
                        setState(() => _isSpeakerOn = !_isSpeakerOn);
                        _webrtcService.toggleSpeaker(_isSpeakerOn);
                      },
                      icon: Icon(
                        _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                        color: Colors.white,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white10,
                      ),
                    ),
                    // End Call Pill Button
                    ElevatedButton.icon(
                      onPressed: _endCall,
                      icon: const Icon(Icons.call_end, color: Colors.white),
                      label: const Text('End Call', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
