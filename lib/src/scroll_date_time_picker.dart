import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:scroll_datetime_picker/src/entities/date_time_picker_helper.dart';
import 'package:scroll_datetime_picker/src/entities/enums.dart';
import 'package:scroll_datetime_picker/src/widgets/picker_widget.dart';

part 'entities/date_time_picker_option.dart';
part 'entities/date_time_picker_style.dart';
part 'entities/date_time_picker_wheel_option.dart';

typedef DateTimePickerItemBuilder = Widget Function(
  BuildContext context,
  String pattern,
  String text,
  bool isActive,
  bool isDisabled,
);

/// A customizable Scrollable DateTimePicker.
///
/// To set a custom datetime format, use DateFormat available in
/// `[dateOption]` param
///
/// To set styles for the picker, use `[style]` param
class ScrollDateTimePicker extends StatefulWidget {
  const ScrollDateTimePicker({
    super.key,
    required this.itemExtent,
    required this.dateOption,
    required this.onChange,
    this.itemBuilder,
    this.style,
    this.disableInitialScrollAnimation = false,
    this.visibleItem = 3,
    this.infiniteScroll = false,
    this.wheelOption = const DateTimePickerWheelOption(),
  });

  /// Height of every item in the picker
  ///
  /// Must not be null
  final double itemExtent;

  /// Number of item to be shown vertically
  ///
  /// Defaults to 3
  final int visibleItem;

  /// Whether to implement infinite scroll or finite scroll.
  ///
  /// Defaults to false
  final bool infiniteScroll;

  /// Callback called when the selected date and/or time changes.
  ///
  /// Must not be null.
  final void Function(DateTime datetime)? onChange;

  /// Set datetime configuration
  ///
  /// Must not be null.
  final DateTimePickerOption dateOption;

  /// Set picker styles.
  ///
  /// If [itemBuilder] is not null, this value will be omitted.
  final DateTimePickerStyle? style;

  /// Set custom appearance for the picker wheel
  ///
  /// The parameters here are based on flutter's [ListWheelScrollView]
  final DateTimePickerWheelOption wheelOption;

  /// Set custom appearance for every item in the picker wheel
  ///
  /// - If null, the appearance of every item will be based on DateTimePickerStyle [style]
  /// - If not null, the appearance of every item will be based return value of this builder
  final DateTimePickerItemBuilder? itemBuilder;

  /// Whether to disable the scroll animation that occurs when the picker is
  /// first displayed.
  final bool disableInitialScrollAnimation;

  @override
  State<ScrollDateTimePicker> createState() => _ScrollDateTimePickerState();
}

class _ScrollDateTimePickerState extends State<ScrollDateTimePicker> {
  late DateTime _activeDate;
  late List<ScrollController> _controllers;

  late DateTimePickerStyle _style;
  late DateTimePickerOption _option;
  late DateTimePickerHelper _helper;

  late final ValueNotifier<bool> isRecheckingPosition;
  bool _isScrollingToDate = false;

  @override
  void initState() {
    super.initState();

    initializeDateFormatting(widget.dateOption.locale.languageCode);
    isRecheckingPosition = ValueNotifier(false);

    _option = widget.dateOption;
    _activeDate = _option.getInitialDate;
    _helper = DateTimePickerHelper(_option);
    _style = widget.style ?? DateTimePickerStyle();
    _controllers = List.generate(
      _option.patterns.length,
      (index) => ScrollController(),
    );

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (widget.disableInitialScrollAnimation) {
        _jumpToDate();
        return;
      }
      _scrollToDate();
    });
  }

  @override
  void didUpdateWidget(covariant ScrollDateTimePicker oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.dateOption != _option) {
      _option = widget.dateOption;
      _helper = DateTimePickerHelper(_option);

      if (_option.patterns.length != _controllers.length) {
        final difference = _option.patterns.length - _controllers.length;
        if (difference.isNegative) {
          _controllers.removeRange(
            _controllers.length - difference.abs(),
            _controllers.length,
          );
        } else {
          _controllers.addAll(
            List.generate(
              difference,
              (_) => ScrollController(),
            ),
          );
        }
      }
    }

    if (widget.dateOption.getInitialDate != _activeDate) {
      _activeDate = widget.dateOption.getInitialDate;
      _scrollToDate();
    }

    if (widget.style != _style) {
      _style = widget.style ?? _style;
    }
  }

  @override
  void dispose() {
    isRecheckingPosition.dispose();
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
      child: Stack(
        alignment: Alignment.center,
        children: [
          /* Center Decoration */
          Container(
            height: widget.itemExtent,
            width: double.infinity,
            decoration: _style.centerDecoration,
          ),

          /* Picker Widget */
          SizedBox(
            width: double.infinity,
            height: widget.itemExtent * widget.visibleItem,
            child: Row(
              children: List.generate(
                _option.patterns.length,
                (colIndex) {
                  final pattern = _option.patterns[colIndex];
                  final type = DateTimeType.fromPattern(pattern);

                  return Expanded(
                    child: PickerWidget(
                      itemExtent: widget.itemExtent,
                      infiniteScroll: widget.infiniteScroll,
                      controller: _controllers[colIndex],
                      onChange: (rowIndex) => _onChange(type, rowIndex),
                      itemCount: _helper.itemCount(type),
                      wheelOption: widget.wheelOption,
                      inactiveBuilder: (rowIndex) {
                        final text = _helper.getText(type, pattern, rowIndex);
                        final isDisabled = _helper.isTextDisabled(
                          type,
                          _activeDate,
                          rowIndex,
                        );

                        return widget.itemBuilder != null
                            ? widget.itemBuilder!(
                                context,
                                pattern,
                                text,
                                false,
                                isDisabled,
                              )
                            : Container(
                                width: double.infinity,
                                height: widget.itemExtent,
                                alignment: Alignment.center,
                                decoration: _style.inactiveDecoration,
                                child: Text(
                                  text,
                                  style: isDisabled
                                      ? _style.disabledStyle
                                      : _style.inactiveStyle,
                                ),
                              );
                      },
                      activeBuilder: (rowIndex) {
                        final text = _helper.getText(type, pattern, rowIndex);
                        final isDisabled = _helper.isTextDisabled(
                          type,
                          _activeDate,
                          rowIndex,
                        );

                        return widget.itemBuilder != null
                            ? widget.itemBuilder!(
                                context,
                                pattern,
                                text,
                                true,
                                isDisabled,
                              )
                            : Container(
                                width: double.infinity,
                                height: widget.itemExtent,
                                alignment: Alignment.center,
                                decoration: _style.activeDecoration,
                                child: Text(
                                  text,
                                  style: isDisabled
                                      ? _style.disabledStyle
                                      : _style.activeStyle,
                                ),
                              );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _scrollToDate() async {
    _isScrollingToDate = true;

    final activeDate = _activeDate;
    final futures = <Future<void>>[];

    for (var i = 0; i < _option.dateTimeTypes.length; i++) {
      late double extent;

      switch (_option.dateTimeTypes[i]) {
        case DateTimeType.year:
          extent = _helper.years.indexOf(activeDate.year).toDouble();
          break;
        case DateTimeType.month:
          extent = activeDate.month - 1;
          break;
        case DateTimeType.day:
          extent = activeDate.day - 1;
          break;
        case DateTimeType.weekday:
          extent = activeDate.weekday - 1;
          break;
        case DateTimeType.hour24:
          extent = activeDate.hour.toDouble();
          break;
        case DateTimeType.hour12:
          extent = _helper.convertToHour12(activeDate.hour) - 1;
          break;
        case DateTimeType.minute:
          extent = activeDate.minute.toDouble();
          break;
        case DateTimeType.second:
          extent = activeDate.second.toDouble();
          break;
        case DateTimeType.amPM:
          extent = _helper.isAM(activeDate.hour) ? 0 : 1;
          break;
      }

      if (_controllers[i].hasClients) {
        futures.add(
          _controllers[i].animateTo(
            widget.itemExtent * extent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          ),
        );
      }
    }

    await Future.wait(futures);

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _isScrollingToDate = false;
    });
  }

  void _jumpToDate() {
    final activeDate = _activeDate;

    for (var i = 0; i < _option.dateTimeTypes.length; i++) {
      late double extent;

      switch (_option.dateTimeTypes[i]) {
        case DateTimeType.year:
          extent = _helper.years.indexOf(activeDate.year).toDouble();
          break;
        case DateTimeType.month:
          extent = activeDate.month - 1;
          break;
        case DateTimeType.day:
          extent = activeDate.day - 1;
          break;
        case DateTimeType.weekday:
          extent = activeDate.weekday - 1;
          break;
        case DateTimeType.hour24:
          extent = activeDate.hour.toDouble();
          break;
        case DateTimeType.hour12:
          extent = _helper.convertToHour12(activeDate.hour) - 1;
          break;
        case DateTimeType.minute:
          extent = activeDate.minute.toDouble();
          break;
        case DateTimeType.second:
          extent = activeDate.second.toDouble();
          break;
        case DateTimeType.amPM:
          extent = _helper.isAM(activeDate.hour) ? 0 : 1;
          break;
      }

      if (_controllers[i].hasClients) {
        _controllers[i].jumpTo(widget.itemExtent * extent);
      }
    }
  }

  Future<void> _onChange(DateTimeType type, int rowIndex) async {
    if (_isScrollingToDate) return;

    var newDate = _helper.getDateFromRowIndex(
      type: type,
      rowIndex: rowIndex,
      activeDate: _activeDate,
    );

    if (newDate.isAfter(_option.maxDate)) newDate = _activeDate;
    if (newDate.isBefore(_option.minDate)) newDate = _activeDate;

    /* Set new date */
    _activeDate = newDate;
    widget.onChange?.call(newDate);

    await _recheckPosition(newDate);
  }

  Future<void> _recheckPosition(DateTime date) async {
    if (isRecheckingPosition.value) return;

    const types = [
      DateTimeType.year,
      DateTimeType.month,
      DateTimeType.day,
      DateTimeType.weekday,
    ];

    isRecheckingPosition.value = true;
    for (final type in types) {
      await _recheckPositionByType(type, date);
    }
    isRecheckingPosition.value = false;
  }

  Future<void> _recheckPositionByType(DateTimeType type, DateTime date) async {
    final index = _option.dateTimeTypes.indexOf(type);
    if (index != -1) {
      late int targetPosition;

      switch (type) {
        case DateTimeType.year:
          targetPosition = _helper.years.indexOf(date.year) + 1;
          break;
        case DateTimeType.month:
          targetPosition = date.month;
          break;
        case DateTimeType.day:
          targetPosition = date.day;
          break;
        case DateTimeType.weekday:
          targetPosition = date.weekday;
          break;
        default:
          break;
      }

      /* Check if other scroll controller is still scrolling */
      await _fixPosition(
        controller: _controllers[index],
        itemCount: _helper.itemCount(type),
        targetPosition: targetPosition,
      );
    }
  }

  Future<void> _fixPosition({
    required ScrollController controller,
    required int itemCount,
    required int targetPosition,
  }) async {
    if (controller.hasClients) {
      final scrollPosition =
          (controller.offset / widget.itemExtent).floor() % itemCount + 1;

      if (targetPosition != scrollPosition) {
        final difference = scrollPosition - targetPosition;
        final endOffset = controller.offset - (difference * widget.itemExtent);

        if (!controller.position.isScrollingNotifier.value) {
          await Future.delayed(
            const Duration(milliseconds: 100),
            () => controller.animateTo(
              endOffset,
              duration: const Duration(milliseconds: 500),
              curve: Curves.bounceOut,
            ),
          );
        }
      }
    }
  }
}
