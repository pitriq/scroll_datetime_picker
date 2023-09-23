import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:scroll_datetime_picker/src/widget/picker_widget.dart';

part '../entities/enums.dart';
part 'date_picker_helper.dart';
part 'date_picker_option.dart';
part 'date_picker_style.dart';

class ScrollDatePicker extends StatefulWidget {
  const ScrollDatePicker({
    super.key,
    required this.itemExtent,
    required this.dateOption,
    this.style,
    this.onChange,
    this.visibleItem = 3,
    this.infiniteScroll = true,
  });

  final double itemExtent;
  final int visibleItem;
  final bool infiniteScroll;

  final void Function(DateTime datetime)? onChange;

  final DatePickerOption dateOption;
  final DatePickerStyle? style;

  @override
  State<ScrollDatePicker> createState() => _ScrollDatePickerState();
}

class _ScrollDatePickerState extends State<ScrollDatePicker> {
  late final List<ScrollController> _controllers;
  late final ValueNotifier<DateTime> _activeDate;

  late final DatePickerStyle _style;
  late final DatePickerOption _option;
  late _Helper _helper;

  @override
  void initState() {
    super.initState();

    initializeDateFormatting(widget.dateOption.locale.languageCode);

    _option = widget.dateOption;
    _activeDate = ValueNotifier<DateTime>(_option.getInitialDate);
    _helper = _Helper(_option);
    _style = widget.style ?? DatePickerStyle();
    _controllers = List.generate(
      _option.patterns.length,
      (index) => ScrollController(),
    );

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _initDate();
    });
  }

  @override
  void dispose() {
    _activeDate.dispose();
    for (final ctrl in _controllers) {
      ctrl.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: widget.itemExtent * widget.visibleItem,
      child: Row(
        children: List.generate(
          _option.patterns.length,
          (colIndex) {
            final pattern = _option.patterns[colIndex];
            final type = _DateTimeType.fromPattern(pattern);

            return Expanded(
              child: PickerWidget(
                itemExtent: widget.itemExtent,
                infiniteScroll: widget.infiniteScroll,
                controller: _controllers[colIndex],
                onChange: (rowIndex) => _onChange(type, rowIndex),
                itemCount: _helper.itemCount(type),
                centerWidget: Container(
                  height: widget.itemExtent,
                  width: double.infinity,
                  decoration: _style.centerDecoration,
                ),
                inactiveBuilder: (rowIndex) {
                  var disabled = false;
                  final maxDate = _helper.maxDate(
                    _activeDate.value.month,
                    _activeDate.value.year,
                  );
                  final itemCount = _helper.itemCount(type);

                  if (type == _DateTimeType.day) {
                    final date = rowIndex % itemCount + 1;
                    if (date > maxDate) disabled = true;
                  }

                  return Text(
                    _helper.getText(type, pattern, rowIndex % itemCount),
                    style:
                        disabled ? _style.disabledStyle : _style.inactiveStyle,
                  );
                },
                activeBuilder: (rowIndex) {
                  var disabled = false;
                  final maxDate = _helper.maxDate(
                    _activeDate.value.month,
                    _activeDate.value.year,
                  );
                  final itemCount = _helper.itemCount(type);

                  if (colIndex == 0) {
                    final date = rowIndex % itemCount + 1;
                    if (date > maxDate) disabled = true;
                  }

                  return Text(
                    _helper.getText(type, pattern, rowIndex % itemCount),
                    style: disabled ? _style.disabledStyle : _style.activeStyle,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _initDate() {
    final activeDate = _activeDate.value;

    for (var i = 0; i < _option.dateTimeTypes.length; i++) {
      late double extent;

      switch (_option.dateTimeTypes[i]) {
        case _DateTimeType.year:
          extent = (_helper.years.indexOf(activeDate.year)).toDouble();
          break;
        case _DateTimeType.month:
          extent = activeDate.month - 1;
          break;
        case _DateTimeType.day:
          extent = activeDate.day - 1;
          break;
        case _DateTimeType.weekday:
          extent = activeDate.weekday - 1;
          break;
        case _DateTimeType.hour24:
          extent = activeDate.hour - 1;
          break;
        case _DateTimeType.hour12:
          extent = _helper.convertToHour12(activeDate.hour) - 1;
          break;
        case _DateTimeType.minute:
          extent = activeDate.minute.toDouble();
          break;
        case _DateTimeType.second:
          extent = activeDate.second.toDouble();
          break;
        case _DateTimeType.amPM:
          extent = _helper.isAM(activeDate.hour) ? 0 : 1;
          break;
      }

      _controllers[i].animateTo(
        widget.itemExtent * extent,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    }
  }

  void _onChange(_DateTimeType type, int rowIndex) {
    late DateTime newDate;
    final activeDate = _activeDate.value;

    switch (type) {
      case _DateTimeType.year:
        var newDay = activeDate.day;
        final newYear = _helper.years[rowIndex];
        final maxDate = _helper.maxDate(activeDate.month, newYear);

        if (newDay > maxDate) newDay = maxDate;

        newDate = activeDate.copyWith(year: newYear, day: newDay);
        break;
      case _DateTimeType.month:
        var newDay = activeDate.day;
        final newMonth = rowIndex + 1;
        final maxDate = _helper.maxDate(newMonth, activeDate.year);

        if (newDay > maxDate) newDay = maxDate;

        newDate = activeDate.copyWith(month: newMonth, day: newDay);
        break;
      case _DateTimeType.day:
        var newDay = rowIndex + 1;
        final maxDate = _helper.maxDate(
          activeDate.month,
          activeDate.year,
        );

        if (newDay > maxDate) newDay = maxDate;
        newDate = activeDate.copyWith(day: newDay);
        break;
      case _DateTimeType.weekday:
        final oldDay = activeDate.weekday;
        final newDay = rowIndex + 1;
        final difference = newDay - oldDay;
        newDate = newDay > oldDay
            ? activeDate.add(Duration(days: difference.abs()))
            : activeDate.subtract(Duration(days: difference.abs()));
        break;
      case _DateTimeType.hour24:
        newDate = activeDate.copyWith(hour: rowIndex);
        break;
      case _DateTimeType.hour12:
        final hour = activeDate.hour;
        final isAM = _helper.isAM(hour);

        var newHour = rowIndex + 1 + (isAM ? 0 : 12);
        if (isAM && newHour == 12) newHour = 0;
        if (!isAM && newHour == 24) newHour = 12;

        newDate = activeDate.copyWith(hour: newHour);
        break;
      case _DateTimeType.minute:
        newDate = activeDate.copyWith(minute: rowIndex);
        break;
      case _DateTimeType.second:
        newDate = activeDate.copyWith(second: rowIndex);
        break;
      case _DateTimeType.amPM:
        final hour = activeDate.hour;
        final isAM = _helper.isAM(hour);
        var newHour = hour;

        // AM
        if (rowIndex == 0 && !isAM) newHour = hour - 12;

        // PM
        if (rowIndex == 1 && isAM) newHour = hour + 12;

        newDate = activeDate.copyWith(hour: newHour);
        break;
    }

    /* ReCheck day value */
    final dayIndex = _option.dateTimeTypes.indexOf(_DateTimeType.day);
    if (dayIndex != -1) {
      _fixPosition(
        controller: _controllers[dayIndex],
        itemCount: 31,
        targetPosition: newDate.day,
      );
    }
    /* ReCheck weekday value */
    final weekdayIndex = _option.dateTimeTypes.indexOf(_DateTimeType.weekday);
    if (weekdayIndex != -1 && type != _DateTimeType.weekday) {
      _fixPosition(
        controller: _controllers[weekdayIndex],
        itemCount: 7,
        targetPosition: newDate.weekday,
      );
    }

    /* Set new date */
    _activeDate.value = newDate;
    widget.onChange?.call(newDate);

    return;
  }

  void _fixPosition({
    required ScrollController controller,
    required int itemCount,
    required int targetPosition,
  }) {
    if (controller.hasClients) {
      final dayScrollPosition =
          (controller.offset / widget.itemExtent).floor() % itemCount + 1;

      if (targetPosition != dayScrollPosition) {
        final difference = dayScrollPosition - targetPosition;
        final endOffset = controller.offset - (difference * widget.itemExtent);

        if (!controller.position.isScrollingNotifier.value) {
          Future.delayed(Duration.zero, () {
            controller.animateTo(
              endOffset,
              duration: const Duration(milliseconds: 500),
              curve: Curves.bounceOut,
            );
          });
        }
      }
    }
  }
}
