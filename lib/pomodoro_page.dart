import 'dart:async';
import 'package:flutter/material.dart';

/// 🔹 Timer Controller
class PomodoroTimerController {
  static Timer? _timer;
  static int durationSeconds = 25 * 60;
  static int remainingSeconds = 25 * 60;
  static bool isRunning = false;
  static bool isPaused = false;
  static DateTime? _endTime;

  static final ValueNotifier<int> remainingNotifier =
  ValueNotifier<int>(remainingSeconds);

  /// Start the timer
  static void start(VoidCallback onComplete) {
    if (isRunning) return;

    _endTime = DateTime.now().add(Duration(seconds: remainingSeconds));

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      if (_endTime != null) {
        final diff = _endTime!.difference(now).inSeconds;
        if (diff > 0) {
          remainingSeconds = diff;
          remainingNotifier.value = remainingSeconds;
        } else {
          stop();
          onComplete();
        }
      }
    });

    isRunning = true;
    isPaused = false;
  }

  /// Pause the timer
  static void pause() {
    _timer?.cancel();
    isPaused = true;
    isRunning = false;
  }

  /// Resume from pause
  static void resume(VoidCallback onComplete) {
    if (isPaused) {
      _endTime = DateTime.now().add(Duration(seconds: remainingSeconds));
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        final now = DateTime.now();
        if (_endTime != null) {
          final diff = _endTime!.difference(now).inSeconds;
          if (diff > 0) {
            remainingSeconds = diff;
            remainingNotifier.value = remainingSeconds;
          } else {
            stop();
            onComplete();
          }
        }
      });
      isRunning = true;
      isPaused = false;
    }
  }

  /// Reset to initial duration
  static void reset() {
    _timer?.cancel();
    remainingSeconds = durationSeconds;
    remainingNotifier.value = remainingSeconds;
    isRunning = false;
    isPaused = false;
    _endTime = null;
  }

  /// Change duration (in minutes)
  static void setDuration(int minutes) {
    _timer?.cancel();
    durationSeconds = minutes * 60;
    remainingSeconds = durationSeconds;
    remainingNotifier.value = remainingSeconds;
    isRunning = false;
    isPaused = false;
    _endTime = null;
  }

  /// Stop completely
  static void stop() {
    _timer?.cancel();
    isRunning = false;
    isPaused = false;
    _endTime = null;
  }
}

/// 🔹 Pomodoro UI
class PomodoroPage extends StatefulWidget {
  final VoidCallback? onSessionComplete;

  const PomodoroPage({Key? key, this.onSessionComplete}) : super(key: key);

  @override
  _PomodoroPageState createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage> {
  final TextEditingController _customTimeController = TextEditingController();

  @override
  void dispose() {
    _customTimeController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  void _onComplete() {
    int breakMinutes = 0;
    if (PomodoroTimerController.durationSeconds == 25 * 60) breakMinutes = 5;
    else if (PomodoroTimerController.durationSeconds == 50 * 60) breakMinutes = 10;
    else if (PomodoroTimerController.durationSeconds == 90 * 60) breakMinutes = 20;
    else breakMinutes = (PomodoroTimerController.durationSeconds / 60 / 5).ceil(); // Custom break

    // 🟢 Trigger parent callback
    if (widget.onSessionComplete != null) {
      widget.onSessionComplete!();
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("✅ Session Complete!"),
          content: Text("Great work! Take a $breakMinutes minute break."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                PomodoroTimerController.reset();
                setState(() {});
              },
              child: const Text("OK"),
            )
          ],
        ),
      );
    }
  }

  void _showCustomTimeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Custom Timer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _customTimeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Minutes',
                hintText: 'Enter custom time (1-180 min)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Recommended: 15-90 minutes for focused study sessions',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2A9D8F)),
            child: const Text('Set Timer', style: TextStyle(color: Colors.white)),
            onPressed: () {
              final customMinutes = int.tryParse(_customTimeController.text);
              if (customMinutes != null && customMinutes > 0 && customMinutes <= 180) {
                PomodoroTimerController.setDuration(customMinutes);
                Navigator.pop(context);
                setState(() {});
                _customTimeController.clear();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid time between 1-180 minutes'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimeOption(int minutes, String label) {
    final isSelected = PomodoroTimerController.durationSeconds == minutes * 60;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFF264653) : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.black,
        elevation: 3,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      onPressed: () {
        PomodoroTimerController.setDuration(minutes);
        setState(() {});
      },
      child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildCustomTimeButton() {
    // Show current custom time if it's not one of the presets
    final currentMinutes = PomodoroTimerController.durationSeconds ~/ 60;
    final isCustom = ![25, 50, 90].contains(currentMinutes);

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isCustom ? const Color(0xFF264653) : Colors.white,
        foregroundColor: isCustom ? Colors.white : Colors.black,
        elevation: 3,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onPressed: _showCustomTimeDialog,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.edit_outlined, size: 16),
          const SizedBox(width: 4),
          Text(
            isCustom ? '${currentMinutes}m' : 'Custom',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F1),
      appBar: AppBar(
        title: const Text(
          'Pomodoro Timer',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF264653),
        elevation: 4,
        shadowColor: Colors.black45,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(height: 24),

          /// 🔹 Timer Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF264653),
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(2, 4),
                )
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Focus Session',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 20),

                /// Circular Progress Timer
                ValueListenableBuilder<int>(
                  valueListenable: PomodoroTimerController.remainingNotifier,
                  builder: (_, seconds, __) {
                    final progress = seconds / PomodoroTimerController.durationSeconds;

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 220,
                          height: 220,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 14,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2A9D8F)),
                          ),
                        ),
                        Text(
                          _formatTime(seconds),
                          style: const TextStyle(
                            fontSize: 46,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          /// 🔹 Control Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!PomodoroTimerController.isRunning && !PomodoroTimerController.isPaused)
                _controlButton("Start", Icons.play_arrow, const Color(0xFF2A9D8F), () {
                  PomodoroTimerController.start(_onComplete);
                  setState(() {});
                }),

              if (PomodoroTimerController.isRunning)
                _controlButton("Pause", Icons.pause, const Color(0xFFE9C46A), () {
                  PomodoroTimerController.pause();
                  setState(() {});
                }),

              if (PomodoroTimerController.isPaused)
                _controlButton("Resume", Icons.play_circle, const Color(0xFF457B9D), () {
                  PomodoroTimerController.resume(_onComplete);
                  setState(() {});
                }),

              const SizedBox(width: 20),
              _controlButton("Reset", Icons.refresh, const Color(0xFFE76F51), () {
                PomodoroTimerController.reset();
                setState(() {});
              }),
            ],
          ),

          const SizedBox(height: 30),

          /// 🔹 Time Options (including Custom)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildTimeOption(25, '25 min'),
              _buildTimeOption(50, '50 min'),
              _buildTimeOption(90, '90 min'),
              _buildCustomTimeButton(),
            ],
          ),

          const Padding(
            padding: EdgeInsets.only(bottom: 24, top: 18),
            child: Text(
              '🌱 Stay focused. Take mindful breaks!',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  /// Reusable button with icon
  Widget _controlButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 5,
      ),
      icon: Icon(icon, size: 22, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }
}
