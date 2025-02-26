import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class QrService {
  final supabase = Supabase.instance.client;
  bool _loading = false;

  Future<bool> markAttendance(String qrData, BuildContext context) async {
    if (_loading) return false;

    try {
      _loading = true;
      final currentTime = DateTime.now();
      final formattedTime =
          DateFormat('MM/dd/yyyy, hh:mm:ss a').format(currentTime);

      debugPrint('Attempting to mark attendance for ID: $qrData');

      final existingReg = await supabase
          .from('eventsregistrations')
          .select()
          .eq('id', qrData)
          .single();

      debugPrint('Full registration data: $existingReg');

      if (existingReg == null) {
        _showAlert(context, 'Error',
            'Registration not found. Please check the QR code and try again.');
        return false;
      }

      if (existingReg['is_approved'] != 'ACCEPTED') {
        _showAlert(
            context, 'Not Approved', 'This registration has not been approved');
        return false;
      }

      if (existingReg['attendance'] == 'Present') {
        _showAlert(context, 'Already Marked',
            'Attendance has already been marked for this registration');
        return false;
      }

      // Try simple update
      debugPrint('Attempting simple attendance update...');
      final simpleUpdate = await supabase
          .from('eventsregistrations')
          .update({'attendance': 'Present'}).match({
        'id': qrData,
        'is_approved': 'ACCEPTED',
        'attendance': 'Absent'
      }).select();

      debugPrint('Simple update result: $simpleUpdate');

      // Verify update
      final checkData = await supabase
          .from('eventsregistrations')
          .select('attendance, details')
          .eq('id', qrData)
          .single();

      debugPrint('Verification data: $checkData');

      if (checkData == null || checkData['attendance'] != 'Present') {
        // Try alternative update method
        debugPrint('Trying alternative update method...');
        await supabase.rpc('mark_attendance', params: {
          'registration_id': qrData,
        });
      }

      // Final verification
      final finalCheck = await supabase
          .from('eventsregistrations')
          .select('attendance')
          .eq('id', qrData)
          .single();

      if (finalCheck == null || finalCheck['attendance'] != 'Present') {
        _showAlert(context, 'Error',
            'Failed to mark attendance after multiple attempts');
        return false;
      }

      // Show success dialog
      if (context.mounted) {
        await showDialog(
          // Add await here
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Success'),
              content: Text(
                  'Attendance marked successfully for ${existingReg['event_title']} at $formattedTime'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/history',
                      arguments: {
                        'qrLink': qrData,
                        'scanTime': formattedTime,
                        'eventTitle': existingReg['event_title'],
                      },
                    );
                  },
                  child: const Text('View History'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Scan Another'),
                ),
              ],
            );
          },
        );
        return true; // Return true after dialog is closed
      }
    } catch (err) {
      debugPrint('Error processing attendance: $err');
      _showAlert(
          context, 'Error', 'An unexpected error occurred. Please try again.');
    } finally {
      _loading = false;
    }
    return false;
  }

  void _showAlert(BuildContext context, String title, String message) {
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }
}
