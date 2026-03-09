
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_lock/flutter_app_lock.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:nullpass/common.dart';
import 'package:nullpass/services/logging.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  _LockScreenState createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final String _title = "NullPass";
  late LocalAuthentication localAuth;
  bool cancelled = false;

  @override
  void initState() {
    super.initState();
    localAuth = LocalAuthentication();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await authenticate();
    });
  }

  Future<void> authenticate() async {
    try {
      setState(() {
        cancelled = false;
      });
      if (canCheckBiometrics) {
        bool didAuthenticate = await localAuth.authenticate(
          localizedReason: "Unlock NullPass",
          options: const AuthenticationOptions(
            stickyAuth: true,
            useErrorDialogs: false,
            biometricOnly: true,
          ),
        );
        if (didAuthenticate) {
          unlock();
        } else {
          setState(() {
            cancelled = true;
          });
        }
      }
    } on PlatformException catch (e) {
      if (e.code == auth_error.passcodeNotSet) {
        Log.debug("The user has not set a passcode:\n\t$e");
      } else if (e.code == auth_error.notEnrolled) {
        Log.debug(
            "The user has not enrolled biometric data on the device:\n\t$e");
      } else if (e.code == auth_error.notAvailable) {
        Log.debug("The biometric scanner not available on this device:\n\t$e");
      } else if (e.code == auth_error.otherOperatingSystem) {
        Log.debug("The OS is not Android or iOS:\n\t$e");
      } else if (e.code == auth_error.lockedOut) {
        Log.debug(
            "The user is currently locked out please try again later:\n\t$e");
      } else if (e.code == auth_error.permanentlyLockedOut) {
        Log.debug("The user is permanently locked out:\n\t$e");
      } else {
        Log.debug(
            "An unknown error occurred while trying to authenticate the user:\n\t$e");
      }
    }
  }

  void unlock() {
    AppLock.of(context)?.didUnlock();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return MaterialApp(
      title: _title,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
      ),
      home: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary,
                colorScheme.secondary,
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  Hero(
                    tag: 'app-logo',
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Image.asset(
                          'assets/images/null_iosScaledDown_1500_Transparent.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'NullPass',
                    style: theme.textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Secure Password Manager',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const Spacer(),
                  if (cancelled)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.fingerprint,
                            size: 64,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: colorScheme.primary,
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            onPressed: () async {
                              await authenticate();
                            },
                            icon: const Icon(Icons.fingerprint, size: 24),
                            label: Text(
                              'Unlock with Biometrics',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!cancelled)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const SizedBox(
                            width: 48,
                            height: 48,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Authenticating...',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
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
      ),
    );
  }
}
