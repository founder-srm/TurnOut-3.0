import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/cupertino.dart';

class Event {
  final String id;
  final String title;

  Event({required this.id, required this.title});
}

class Registration {
  final String id;
  final String email;
  final String attendance;
  final String eventTitle;

  Registration({
    required this.id,
    required this.email,
    required this.attendance,
    required this.eventTitle,
  });
}

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({Key? key}) : super(key: key);

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String? selectedEventId;
  List<Event> events = [];
  List<Registration> registrations = [];
  bool isLoading = true;
  bool showEventPicker = false;
  final searchController = TextEditingController();
  final supabase = Supabase.instance.client;
  int selectedSegment = 0; // 0 for all, 1 for present, 2 for absent

  @override
  void initState() {
    super.initState();
    fetchEvents();
  }

  Future<void> fetchEvents() async {
    try {
      final response = await supabase
          .from('events')
          .select('id, title')
          .order('created_at', ascending: false);

      final List<Event> fetchedEvents = (response as List)
          .map((event) => Event(id: event['id'], title: event['title']))
          .toList();

      setState(() {
        events = fetchedEvents;
        if (events.isNotEmpty) {
          selectedEventId = events[0].id;
          fetchRegistrations();
        }
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load events')),
      );
    }
  }

  Future<void> fetchRegistrations() async {
    if (selectedEventId == null) return;

    try {
      setState(() => isLoading = true);

      final response = await supabase
          .from('eventsregistrations')
          .select('id, registration_email, attendance, event_title')
          .eq('event_id', selectedEventId!)
          .eq('is_approved', 'ACCEPTED');

      final List<Registration> fetchedRegistrations = (response as List)
          .map((reg) => Registration(
                id: reg['id'],
                email: reg['registration_email'],
                attendance: reg['attendance'],
                eventTitle: reg['event_title'],
              ))
          .toList();

      setState(() {
        registrations = fetchedRegistrations;
        isLoading = false;
      });
    } catch (error) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load registrations')),
      );
    }
  }

  Future<void> toggleAttendance(Registration registration) async {
    final newAttendance =
        registration.attendance == 'Present' ? 'Absent' : 'Present';

    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Attendance Change'),
        content: Text(
            'Are you sure you want to mark ${registration.email} as $newAttendance?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await supabase.rpc('toggle_attendance', params: {
        'registration_id': registration.id,
        'new_attendance': newAttendance,
      });

      await fetchRegistrations();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Attendance marked as $newAttendance')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to toggle attendance')),
      );
    }
  }

  Future<void> resetAttendance() async {
    if (selectedEventId == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Reset'),
        content: const Text(
            'Are you sure you want to reset attendance for all students?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await supabase.rpc('reset_attendance',
                    params: {'input_event_id': selectedEventId});
                await fetchRegistrations();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Attendance has been reset for all registrations')),
                );
              } catch (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to reset attendance')),
                );
              }
            },
            child: const Text('Reset'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredRegistrations = registrations.where((registration) {
      final matchesSearch = registration.email
          .toLowerCase()
          .contains(searchController.text.toLowerCase());

      switch (selectedSegment) {
        case 1: // Present
          return matchesSearch && registration.attendance == 'Present';
        case 2: // Absent
          return matchesSearch && registration.attendance == 'Absent';
        default: // All
          return matchesSearch;
      }
    }).toList();

    final presentCount =
        filteredRegistrations.where((r) => r.attendance == 'Present').length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    color: const Color(0xFFF8BB0F),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Attendance',
                      style: TextStyle(
                        fontFamily: 'Euclid',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Event Selector
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8BB0F).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedEventId,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down,
                        color: Color(0xFFF8BB0F)),
                    style: const TextStyle(
                      fontFamily: 'Euclid',
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A1A),
                    ),
                    hint: const Text('Select Event'),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedEventId = newValue;
                        fetchRegistrations();
                      });
                    },
                    items: events.map((Event event) {
                      return DropdownMenuItem<String>(
                        value: event.id,
                        child: Text(event.title),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Search and Stats Row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: searchController,
                        style: const TextStyle(fontFamily: 'Euclid'),
                        decoration: const InputDecoration(
                          hintText: 'Search emails...',
                          border: InputBorder.none,
                          icon: Icon(Icons.search, color: Color(0xFFF8BB0F)),
                        ),
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '$presentCount/${filteredRegistrations.length}',
                    style: const TextStyle(
                      fontFamily: 'Euclid',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF8BB0F),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Segmented Control
              Center(
                child: CupertinoSlidingSegmentedControl(
                  groupValue: selectedSegment,
                  backgroundColor: Colors.grey[200]!,
                  thumbColor: const Color(0xFFF8BB0F),
                  children: const {
                    0: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child:
                          Text('All', style: TextStyle(fontFamily: 'Euclid')),
                    ),
                    1: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text('Present',
                          style: TextStyle(fontFamily: 'Euclid')),
                    ),
                    2: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text('Absent',
                          style: TextStyle(fontFamily: 'Euclid')),
                    ),
                  },
                  onValueChanged: (int? value) {
                    setState(() => selectedSegment = value ?? 0);
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Registrations List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: fetchRegistrations,
                  color: const Color(0xFFF8BB0F),
                  child: ListView.builder(
                    itemCount: filteredRegistrations.length,
                    itemBuilder: (context, index) {
                      final registration = filteredRegistrations[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFF8BB0F).withOpacity(0.4),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          onTap: () => toggleAttendance(registration),
                          title: Text(
                            registration.email,
                            style: const TextStyle(
                              fontFamily: 'Euclid',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: registration.attendance == 'Present'
                                  ? const Color(0xFFF8BB0F).withOpacity(0.1)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              registration.attendance,
                              style: TextStyle(
                                fontFamily: 'Euclid',
                                color: registration.attendance == 'Present'
                                    ? const Color(0xFFF8BB0F)
                                    : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
