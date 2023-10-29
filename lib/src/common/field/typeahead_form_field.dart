import 'package:flutter/material.dart';
import 'package:flutter_typeahead/src/common/field/typeahead_field_config.dart';
import 'package:flutter_typeahead/src/common/suggestions_box/suggestions_box_controller.dart';
import 'package:flutter_typeahead/src/common/suggestions_box/suggestions_box_decoration.dart';
import 'package:flutter_typeahead/src/common/suggestions_box/text_field_configuration.dart';
import 'package:flutter_typeahead/src/material/field/typeahead_field.dart';
import 'package:flutter_typeahead/src/typedef.dart';

/// A [FormField](https://docs.flutter.io/flutter/widgets/FormField-class.html)
/// implementation of [TypeAheadField], that allows the value to be saved,
/// validated, etc.
///
/// See also:
///
/// * [TypeAheadField], A [TextField](https://docs.flutter.io/flutter/material/TextField-class.html)
/// that displays a list of suggestions as the user types
abstract class BaseTypeAheadFormField<T> extends FormField<String>
    implements TypeaheadFieldConfig<T> {
  /// Creates a [TypeAheadFormField].
  BaseTypeAheadFormField({
    super.key,
    String? initialValue,
    super.enabled = true,
    super.autovalidateMode,
    super.onSaved,
    this.onReset,
    super.validator,
    this.errorBuilder,
    this.noItemsFoundBuilder,
    this.loadingBuilder,
    this.debounceDuration = const Duration(milliseconds: 300),
    this.scrollController,
    this.suggestionsBoxController,
    required this.onSuggestionSelected,
    required this.itemBuilder,
    this.itemSeparatorBuilder,
    this.layoutArchitecture,
    required this.suggestionsCallback,
    this.suggestionsBoxVerticalOffset = 5,
    required this.textFieldConfiguration,
    this.transitionBuilder,
    this.animationDuration = const Duration(milliseconds: 500),
    this.animationStart = 0.25,
    this.direction = AxisDirection.down,
    this.hideOnLoading = false,
    this.hideOnEmpty = false,
    this.hideOnError = false,
    this.hideSuggestionsOnKeyboardHide = true,
    this.intercepting = false,
    this.keepSuggestionsOnLoading = true,
    this.keepSuggestionsOnSelect = false,
    this.autoFlipDirection = false,
    this.autoFlipListDirection = true,
    this.autoFlipMinHeight = 64,
    this.minCharsForSuggestions = 0,
    this.hideKeyboardOnDrag = false,
    this.ignoreAccessibleNavigation = false,
  })  : assert(
          initialValue == null || textFieldConfiguration.controller == null,
          'initialValue and controller cannot both be set.',
        ),
        assert(minCharsForSuggestions >= 0),
        super(
          initialValue: textFieldConfiguration.controller != null
              ? textFieldConfiguration.controller!.text
              : (initialValue ?? ''),
          // This is a Stub. The builder is overridden below.
          builder: (_) => throw UnimplementedError(
            'BaseTypeAheadFormField.builder must be overridden',
          ),
        );

  /// The configuration of the [TextField](https://docs.flutter.io/flutter/material/TextField-class.html)
  /// that the TypeAhead widget displays
  @override
  final BaseTextFieldConfiguration textFieldConfiguration;

  // Adds a callback for resetting the form field
  final VoidCallback? onReset;

  /// The decoration of the sheet that contains the suggestions.
  @override
  BaseSuggestionsBoxDecoration? get suggestionsBoxDecoration;

  @override
  final Duration animationDuration;
  @override
  final double animationStart;
  @override
  final bool autoFlipDirection;
  @override
  final bool autoFlipListDirection;
  @override
  final double autoFlipMinHeight;
  @override
  final Duration debounceDuration;
  @override
  final AxisDirection direction;
  @override
  final ErrorBuilder? errorBuilder;
  @override
  final bool hideKeyboardOnDrag;
  @override
  final bool hideOnEmpty;
  @override
  final bool hideOnError;
  @override
  final bool hideOnLoading;
  @override
  final bool hideSuggestionsOnKeyboardHide;
  @override
  final bool ignoreAccessibleNavigation;
  @override
  final ItemBuilder<T> itemBuilder;
  @override
  final IndexedWidgetBuilder? itemSeparatorBuilder;
  @override
  final bool intercepting;
  @override
  final bool keepSuggestionsOnLoading;
  @override
  final bool keepSuggestionsOnSelect;
  @override
  final LayoutArchitecture? layoutArchitecture;
  @override
  final WidgetBuilder? loadingBuilder;
  @override
  final int minCharsForSuggestions;
  @override
  final WidgetBuilder? noItemsFoundBuilder;
  @override
  final SuggestionSelectionCallback<T> onSuggestionSelected;
  @override
  final ScrollController? scrollController;
  @override
  final SuggestionsBoxController? suggestionsBoxController;
  @override
  final SuggestionsCallback<T> suggestionsCallback;
  @override
  final double suggestionsBoxVerticalOffset;
  @override
  final AnimationTransitionBuilder? transitionBuilder;

  Widget buildTextField(
    BaseTypeAheadFormFieldState<T> field,
    BaseTextFieldConfiguration config,
  );

  @override
  FormFieldBuilder<String> get builder => (field) {
        final BaseTypeAheadFormFieldState<T> state =
            field as BaseTypeAheadFormFieldState<T>;
        return buildTextField(
          state,
          textFieldConfiguration.copyWith(
            onChanged: (text) {
              state.didChange(text);
              textFieldConfiguration.onChanged?.call(text);
            },
            controller: state._effectiveController,
          ),
        );
      };

  @override
  FormFieldState<String> createState() => BaseTypeAheadFormFieldState<T>();
}

class BaseTypeAheadFormFieldState<T> extends FormFieldState<String> {
  TextEditingController? _controller;

  TextEditingController? get _effectiveController =>
      widget.textFieldConfiguration.controller ?? _controller;

  @override
  BaseTypeAheadFormField get widget =>
      super.widget as BaseTypeAheadFormField<dynamic>;

  @override
  void initState() {
    super.initState();
    if (widget.textFieldConfiguration.controller == null) {
      _controller = TextEditingController(text: widget.initialValue);
    } else {
      widget.textFieldConfiguration.controller!
          .addListener(_handleControllerChanged);
    }
  }

  @override
  void didUpdateWidget(BaseTypeAheadFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.textFieldConfiguration.controller !=
        oldWidget.textFieldConfiguration.controller) {
      oldWidget.textFieldConfiguration.controller
          ?.removeListener(_handleControllerChanged);
      widget.textFieldConfiguration.controller
          ?.addListener(_handleControllerChanged);

      if (oldWidget.textFieldConfiguration.controller != null &&
          widget.textFieldConfiguration.controller == null) {
        _controller = TextEditingController.fromValue(
            oldWidget.textFieldConfiguration.controller!.value);
      }
      if (widget.textFieldConfiguration.controller != null) {
        setValue(widget.textFieldConfiguration.controller!.text);
        if (oldWidget.textFieldConfiguration.controller == null) {
          _controller = null;
        }
      }
    }
  }

  @override
  void dispose() {
    widget.textFieldConfiguration.controller
        ?.removeListener(_handleControllerChanged);
    super.dispose();
  }

  @override
  void reset() {
    super.reset();
    setState(() {
      _effectiveController!.text = widget.initialValue!;
      if (widget.onReset != null) {
        widget.onReset!();
      }
    });
  }

  void _handleControllerChanged() {
    // Suppress changes that originated from within this class.
    //
    // In the case where a controller has been passed in to this widget, we
    // register this change listener. In these cases, we'll also receive change
    // notifications for changes originating from within this class -- for
    // example, the reset() method. In such cases, the FormField value will
    // already have been set.
    if (_effectiveController!.text != value) {
      didChange(_effectiveController!.text);
    }
  }
}