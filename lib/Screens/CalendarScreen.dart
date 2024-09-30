import 'dart:collection';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:vfu/Controllers/services.dart';
import 'package:vfu/Screens/animated_text.dart';

import '../Util/util.dart';
import '../Utils/AppColors.dart';
import '../Widgets/Drawer/DrawerItems.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final ValueNotifier<List<Event>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode
      .toggledOff; // Can be toggled on/off by longpressing a date
  DateTime _focusedDay = DateTime.utc(
      DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  late Future<LinkedHashMap<DateTime, List<Event>>> dayEvents;
  LinkedHashMap<DateTime, List<Event>> eventsList = LinkedHashMap();

  @override
  void initState() {
    super.initState();

    _selectedDay = _focusedDay;
    dayEvents = _initializeSelectedEvents();
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  Future<LinkedHashMap<DateTime, List<Event>>>
      _initializeSelectedEvents() async {
    LinkedHashMap<DateTime, List<Event>> fetchedDayEvents =
        await fetchRepaymentDates();

    return fetchedDayEvents;
  }

  Future<LinkedHashMap<DateTime, List<Event>>> fetchRepaymentDates() async {
    // Define the URL with userData.id
    try {
      AuthController authController = AuthController();

      final response = await authController.getCalendar();
      if (response['status'] == "success") {
        final List<dynamic> eventData = response['calendar'];
        log("Calendar data: $eventData");
        final LinkedHashMap<DateTime, List<Event>> updatedEvents =
            LinkedHashMap();

        for (var event in eventData) {
          final DateTime nextRepaymentDate =
              DateTime.parse(event['start']);
          final String eventTitle = event['title'];
          final newEvent = Event(
            nextRepaymentDate: nextRepaymentDate.toString(),
            title: eventTitle,
          );

          for (var date in daysInRange(nextRepaymentDate, nextRepaymentDate)) {
            if (updatedEvents.containsKey(date)) {
              updatedEvents[date]!.add(newEvent);
            } else {
              updatedEvents[date] = [newEvent];
            }
          }
        }

        log("Updated events: $updatedEvents");
        // Return the updated events data structure
        return updatedEvents;
      } else {
        log("Error fetching repayment dates else: ${response['message']}");
        // Return an empty map if fetching fails
        return LinkedHashMap();
      }
    } catch (e) {
      log("Error fetching repayment dates: $e");
      // Return an empty map if an error occurs
      return LinkedHashMap();
    }
  }

  List<Event> _getEventsForDay(DateTime day) {
    // Implementation example
    return eventsList[day] ?? [];
  }

  Future<List<Event>> _getEventsForRange(DateTime start, DateTime end) async {
    // Wait for the events to be fetched and updated
    final updatedEvents = await fetchRepaymentDates();

    // Now you can safely access the events for the range
    final List<DateTime> days = daysInRange(start, end);
    final List<Event> eventsForRange = [];

    for (final day in days) {
      eventsForRange.addAll(updatedEvents[day] ?? []);
    }

    return eventsForRange;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _rangeStart = null; // Important to clean those
        _rangeEnd = null;
        _rangeSelectionMode = RangeSelectionMode.toggledOff;
      });

      // Wait for the events to be fetched and updated
      final events = _getEventsForDay(selectedDay);
      _selectedEvents.value = events;
    }
  }

  void _onRangeSelected(
      DateTime? start, DateTime? end, DateTime focusedDay) async {
    setState(() {
      _selectedDay = null;
      _focusedDay = focusedDay;
      _rangeStart = start;
      _rangeEnd = end;
      _rangeSelectionMode = RangeSelectionMode.toggledOn;
    });

    // `start` or `end` could be null
    if (start != null && end != null) {
      final events = await _getEventsForRange(start, end);
      _selectedEvents.value = events;
    } else if (start != null) {
      final events = _getEventsForDay(start);
      _selectedEvents.value = events;
    } else if (end != null) {
      final events = _getEventsForDay(end);
      _selectedEvents.value = events;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'NEXT REPAYMENT DATE CALENDAR',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.contentColorOrange,
      ),
      drawer: Drawer(
        backgroundColor: AppColors.contentColorOrange,
        width: size.width * 0.8,
        child: const DrawerItems(),
      ),
      body: FutureBuilder(
          future: dayEvents,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Colors.white,
                body: Center(
                  child: AnimatedLoadingText(
                    loadingTexts: [
                      "Fetching payment dates..",
                      "Please wait...",
                    ],
                  ),
                ),
              );
            } else if (snapshot.hasError) {
              return Scaffold(
                backgroundColor: Colors.white,
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/empty_events.jpg',
                        height: size.height * 0.3,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "An error occurred while fetching repayments",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              eventsList =
                  snapshot.data as LinkedHashMap<DateTime, List<Event>>;

              final events = _getEventsForDay(_selectedDay!);
              //set the selected events to the value notifier
              _selectedEvents.value = events;
              return Stack(
                children: [
                  Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Color.fromARGB(255, 226, 146, 122)),
                  ClipPath(
                    clipper: MyClipper(),
                    child: Container(
                      width: double.infinity,
                      height: size.height * 0.3,
                      color: Colors.white,
                    ),
                  ),
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        TableCalendar<Event>(
                          firstDay: kFirstDay,
                          lastDay: kLastDay,
                          focusedDay: _focusedDay,
                          selectedDayPredicate: (day) =>
                              isSameDay(_selectedDay, day),
                          rangeStartDay: _rangeStart,
                          rangeEndDay: _rangeEnd,
                          availableCalendarFormats: const {
                            CalendarFormat.month: 'Month',
                          },
                          rangeSelectionMode: _rangeSelectionMode,
                          eventLoader: _getEventsForDay,
                          startingDayOfWeek: StartingDayOfWeek.monday,
                          calendarStyle: const CalendarStyle(
                            outsideDaysVisible: false,
                            todayDecoration: BoxDecoration(
                              color: AppColors.contentColorOrange,
                              shape: BoxShape.circle,
                            ),
                            markerDecoration: BoxDecoration(
                              color: AppColors.contentColorOrange,
                              shape: BoxShape.circle,
                            ),
                            weekendTextStyle: TextStyle(
                                color: AppColors.contentColorOrange,
                                fontWeight: FontWeight.bold),
                            selectedDecoration: BoxDecoration(
                              color: AppColors.contentColorOrange,
                              shape: BoxShape.rectangle,
                            ),
                          ),
                          onDaySelected: _onDaySelected,
                          onRangeSelected: _onRangeSelected,
                          onFormatChanged: (format) {
                            if (_calendarFormat != format) {
                              setState(() {
                                _calendarFormat = format;
                              });
                            }
                          },
                          onPageChanged: (focusedDay) {
                            _focusedDay = focusedDay;
                          },
                          calendarBuilders: CalendarBuilders(
                            markerBuilder: (context, date, events) {
                              if (events.isEmpty) return const SizedBox();

                              // Use Row for horizontal distribution
                              return Row(
                                mainAxisSize: MainAxisSize
                                    .min, // Prevent exceeding available space
                                mainAxisAlignment: MainAxisAlignment
                                    .spaceBetween, // Distribute equally
                                children: events.map((event) {
                                  return Container(
                                    margin: const EdgeInsets.only(
                                        top: 26.0), // Adjust spacing
                                    padding: const EdgeInsets.only(
                                        left: 6.0,
                                        right: 6.0), // Adjust padding
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.contentColorOrange,
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        const SizedBox(height: 8.0),
                        const Text(
                          'Number of Group Repayments',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(
                          height: size.height * 0.4,
                          child: _selectedEvents.value.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/empty_events.jpg', // Replace with your image path
                                        height: size.height * 0.28,
                                      ),
                                      const SizedBox(height: 20),
                                      const Text(
                                        "No Repayments found for the selected date",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _selectedEvents.value.length,
                                  itemBuilder: (context, index) {
                                    final event = _selectedEvents.value[index];
                                    return Card(
                                      margin: const EdgeInsets.all(8.0),
                                      elevation: 4.0,
                                      color: AppColors.contentColorOrange,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16.0),
                                      ),
                                      child: ListTile(
                                        leading: const Icon(
                                          Icons.calendar_today,
                                          color: Colors.white,
                                        ),
                                        title: Text(
                                          event.title,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        trailing: const Icon(
                                          Icons.calendar_today_sharp,
                                          color: AppColors.contentColorOrange
                                        ),
                                        onTap: () {
                                          //check if cpd or event
                                          //
                                          print("Event tapped");
                                        },
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
          }),
    );
  }
}

class MyClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
    path.lineTo(0, size.height * 0.8);
    path.quadraticBezierTo(
        size.width * 0.5, size.height, size.width, size.height * 0.8);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
