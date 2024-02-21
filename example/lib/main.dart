import 'package:device_preview/device_preview.dart';
import 'package:example/customizer/screens/customizer_screen.dart';
import 'package:example/theme/app_color.dart';
import 'package:example/theme/app_theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:scroll_datetime_picker/scroll_datetime_picker.dart';

void main() {
  initializeDateFormatting('en');

  runApp(
    DevicePreview(
      builder: (context) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: AppTheme.themeData,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  DateTime? date = DateTime.now();
  DateTime? time = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Scroll DateTime Picker'),
      ),
      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
          },
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              const SizedBox(height: 20),

              /* DATE */
              ScrollDateTimePicker(
                itemExtent: 54,
                onChange: (datetime) => setState(() {
                  date = datetime;
                }),
                dateOption: DateTimePickerOption(
                  dateFormat: DateFormat(
                    'EddMMMy',
                    DevicePreview.locale(context)?.languageCode,
                  ),
                  minDate: DateTime(2000, 6),
                  maxDate: DateTime(2024, 6),
                  initialDate: date,
                ),
                wheelOption: const DateTimePickerWheelOption(
                  offAxisFraction: 1.25,
                  perspective: 0.01,
                  squeeze: 1.2,
                ),
                style: DateTimePickerStyle(
                  centerDecoration: BoxDecoration(
                    color: AppColor.secondary,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(width: 3),
                  ),
                  activeStyle: TextStyle(
                    fontSize: 24,
                    letterSpacing: -0.5,
                    color: Theme.of(context).primaryColor,
                  ),
                  inactiveStyle: TextStyle(
                    fontSize: 20,
                    color: Theme.of(context).primaryColor.withOpacity(0.7),
                  ),
                  disabledStyle: TextStyle(
                    fontSize: 20,
                    color: Theme.of(context).disabledColor,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              /* TIME */
              ScrollDateTimePicker(
                itemExtent: 54,
                infiniteScroll: true,
                dateOption: DateTimePickerOption(
                  dateFormat: DateFormat(
                    'hhmmss a',
                    DevicePreview.locale(context)?.languageCode,
                  ),
                  minDate: DateTime(2000, 6),
                  maxDate: DateTime(2024, 6),
                  initialDate: time,
                ),
                onChange: (datetime) => setState(() {
                  time = datetime;
                }),
                style: DateTimePickerStyle(
                  centerDecoration: const BoxDecoration(
                    color: AppColor.primary,
                    border: Border(
                      top: BorderSide(width: 3),
                      bottom: BorderSide(width: 3),
                    ),
                  ),
                  activeStyle: const TextStyle(
                    fontSize: 28,
                    letterSpacing: -0.5,
                    color: AppColor.secondary,
                  ),
                  inactiveStyle: TextStyle(
                    fontSize: 20,
                    color: Theme.of(context).primaryColor.withOpacity(0.7),
                  ),
                  disabledStyle: TextStyle(
                    fontSize: 20,
                    color: Theme.of(context).disabledColor,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              /* Active Date */
              Text(
                date != null
                    ? DateFormat(
                        'EEEE dd MMMM yyyy',
                        DevicePreview.locale(context)?.languageCode,
                      ).format(date!)
                    : 'null',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              Text(
                time != null
                    ? DateFormat(
                        'HH:mm:ss',
                        DevicePreview.locale(context)?.languageCode,
                      ).format(time!)
                    : 'null',
                style: Theme.of(context).textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              /* Set date now */
              Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ButtonStyle(
                        foregroundColor: MaterialStateProperty.resolveWith(
                          (states) => AppColor.black,
                        ),
                        backgroundColor:
                            MaterialStateProperty.resolveWith<Color>(
                          (states) => states.contains(MaterialState.hovered)
                              ? AppColor.secondary.withOpacity(0.8)
                              : AppColor.secondary,
                        ),
                        side: MaterialStateProperty.resolveWith<BorderSide>(
                          (states) => const BorderSide(width: 3),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          date = null;
                          time = null;
                        });
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Clear',
                                style: TextStyle(fontSize: 20),
                                maxLines: 1,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ButtonStyle(
                        foregroundColor: MaterialStateProperty.resolveWith(
                          (states) => AppColor.white,
                        ),
                        backgroundColor:
                            MaterialStateProperty.resolveWith<Color>(
                          (states) => states.contains(MaterialState.hovered)
                              ? AppColor.primary.withOpacity(0.8)
                              : AppColor.primary,
                        ),
                        side: MaterialStateProperty.resolveWith<BorderSide>(
                          (states) => const BorderSide(width: 3),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          date = DateTime.now();
                          time = DateTime.now();
                        });
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Set Date Now',
                                style: TextStyle(fontSize: 20),
                                maxLines: 1,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),

              /* Customizer */
              Container(
                margin: const EdgeInsets.all(16),
                child: ElevatedButton(
                  style: ButtonStyle(
                    foregroundColor: MaterialStateProperty.resolveWith(
                      (states) => AppColor.black,
                    ),
                    backgroundColor: MaterialStateProperty.resolveWith<Color>(
                      (states) => states.contains(MaterialState.hovered)
                          ? AppColor.secondary.withOpacity(0.8)
                          : AppColor.secondary,
                    ),
                    side: MaterialStateProperty.resolveWith<BorderSide>(
                      (states) => const BorderSide(width: 3),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<Widget>(
                      builder: (context) => const CustomizerScreen(),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Customize Here',
                          style: TextStyle(fontSize: 30),
                        ),
                        Icon(
                          Icons.arrow_right_alt,
                          size: 40,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
