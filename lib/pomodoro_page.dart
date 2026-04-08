import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

/// 🔹 Timer Controller
class PomodoroTimerController {
  static Timer? _timer;
  static int durationSeconds = 25 * 60;
  static int remainingSeconds = 25 * 60;
  static bool isRunning = false;
  static bool isPaused = false;
  static DateTime? _endTime;

  static final ValueNotifier<int> remainingNotifier = ValueNotifier<int>(
    remainingSeconds,
  );

  /// Notifier that increments each time a session completes.
  /// Any page can listen to this to show the break popup globally.
  static final ValueNotifier<int> completionNotifier = ValueNotifier<int>(0);

  /// Helper to compute recommended break minutes based on session duration
  static int get recommendedBreakMinutes {
    if (durationSeconds == 25 * 60) return 5;
    if (durationSeconds == 50 * 60) return 10;
    if (durationSeconds == 90 * 60) return 20;
    return (durationSeconds / 60 / 5).ceil();
  }

  static void _onTimerTick() {
    final now = DateTime.now();
    if (_endTime != null) {
      final diff = _endTime!.difference(now).inSeconds;
      if (diff > 0) {
        remainingSeconds = diff;
        remainingNotifier.value = remainingSeconds;
      } else {
        // Timer finished — update display to 0, then notify
        remainingSeconds = 0;
        remainingNotifier.value = 0;
        _timer?.cancel();
        _timer = null;
        isRunning = false;
        isPaused = false;
        _endTime = null;
        // Signal completion to all listeners
        completionNotifier.value++;
      }
    }
  }

  /// Start the timer
  static void start() {
    if (isRunning) return;

    _endTime = DateTime.now().add(Duration(seconds: remainingSeconds));

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _onTimerTick();
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
  static void resume() {
    if (isPaused) {
      _endTime = DateTime.now().add(Duration(seconds: remainingSeconds));
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        _onTimerTick();
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

  /// Called on login/logout to ensure each student gets a fresh timer.
  /// Stops any running timer and resets all state to safe defaults.
  static void resetForNewUser() {
    _timer?.cancel();
    _timer = null;
    durationSeconds = 25 * 60;
    remainingSeconds = 25 * 60;
    remainingNotifier.value = 25 * 60;
    completionNotifier.value = 0;
    isRunning = false;
    isPaused = false;
    _endTime = null;
  }
}

/// 🔹 Pomodoro UI
class PomodoroPage extends StatefulWidget {
  const PomodoroPage({Key? key}) : super(key: key);

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

  void _showCustomTimeDialog() {
    final tp = Provider.of<ThemeProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: tp.cardBg,
        title: Text(
          'Set Custom Timer',
          style: TextStyle(color: tp.primaryText),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _customTimeController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: tp.primaryText),
              decoration: InputDecoration(
                labelText: 'Minutes',
                labelStyle: TextStyle(color: tp.secondaryText),
                hintText: 'Enter custom time (1-180 min)',
                hintStyle: TextStyle(color: tp.inactiveColor),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Recommended: 15-90 minutes for focused study sessions',
              style: TextStyle(fontSize: 12, color: tp.inactiveColor),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: tp.accentTeal),
            child: const Text(
              'Set Timer',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () {
              final customMinutes = int.tryParse(_customTimeController.text);
              if (customMinutes != null &&
                  customMinutes > 0 &&
                  customMinutes <= 180) {
                PomodoroTimerController.setDuration(customMinutes);
                Navigator.pop(context);
                setState(() {});
                _customTimeController.clear();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Please enter a valid time between 1-180 minutes',
                    ),
                    backgroundColor: tp.accentTeal,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimeOption(ThemeProvider tp, int minutes, String label) {
    final isSelected = PomodoroTimerController.durationSeconds == minutes * 60;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? tp.appBarBg : tp.cardBg,
        foregroundColor: isSelected ? Colors.white : tp.primaryText,
        elevation: 3,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      onPressed: () {
        PomodoroTimerController.setDuration(minutes);
        setState(() {});
      },
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildCustomTimeButton(ThemeProvider tp) {
    // Show current custom time if it's not one of the presets
    final currentMinutes = PomodoroTimerController.durationSeconds ~/ 60;
    final isCustom = ![25, 50, 90].contains(currentMinutes);

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isCustom ? tp.appBarBg : tp.cardBg,
        foregroundColor: isCustom ? Colors.white : tp.primaryText,
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
    final tp = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: tp.scaffoldBg,
      appBar: AppBar(
        title: const Text(
          'Pomodoro Timer',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: tp.appBarBg,
        elevation: 4,
        shadowColor: tp.shadowColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 24),

            /// 🔹 Timer Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: tp.appBarBg,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: tp.shadowColor,
                    blurRadius: 10,
                    offset: Offset(2, 4),
                  ),
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
                      final progress =
                          seconds / PomodoroTimerController.durationSeconds;

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
                              valueColor: AlwaysStoppedAnimation<Color>(
                                tp.accentTeal,
                              ),
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
                if (!PomodoroTimerController.isRunning &&
                    !PomodoroTimerController.isPaused)
                  _controlButton("Start", Icons.play_arrow, tp.accentTeal, () {
                    PomodoroTimerController.start();
                    setState(() {});
                  }),

                if (PomodoroTimerController.isRunning)
                  _controlButton("Pause", Icons.pause, tp.accentAmber, () {
                    PomodoroTimerController.pause();
                    setState(() {});
                  }),

                if (PomodoroTimerController.isPaused)
                  _controlButton("Start", Icons.play_arrow, tp.accentTeal, () {
                    PomodoroTimerController.resume();
                    setState(() {});
                  }),

                const SizedBox(width: 20),
                _controlButton("Reset", Icons.refresh, tp.accentCoral, () {
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
                _buildTimeOption(tp, 25, '25 min'),
                _buildTimeOption(tp, 50, '50 min'),
                _buildTimeOption(tp, 90, '90 min'),
                _buildCustomTimeButton(tp),
              ],
            ),

            Padding(
              padding: EdgeInsets.only(bottom: 24, top: 18),
              child: Text(
                '🌱 Stay focused. Take mindful breaks!',
                style: TextStyle(fontSize: 16, color: tp.secondaryText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Reusable button with icon
  Widget _controlButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
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
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
