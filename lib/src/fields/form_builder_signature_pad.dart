import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:signature/signature.dart';

/// Field with drawing pad on which user can doodle
class FormBuilderSignaturePad extends FormBuilderField<Uint8List> {
  /// Controls the value of the signature pad.
  ///
  /// If null, this widget will create its own [SignatureController].
  ///
  /// If your controller has the "onDrawEnd" method, your method will be executed first and then the values will be saved in the form field
  ///  _controller.onDrawEnd = () async {
  ///       onDrawEnd?.call();
  ///       requestFocus();
  ///       final val = await _getControllerValue();
  ///       didChange(val);
  ///     };
  final SignatureController? controller;

  /// Width of the canvas
  final double? width;

  /// Height of the canvas
  final double height;

  /// Color of the canvas
  final Color backgroundColor;

  /// Text to be displayed on the clear button which clears user input from the canvas
  final String? clearButtonText;

  /// Styles the canvas border
  final Border? border;

  /// Creates field with drawing pad on which user can doodle
  FormBuilderSignaturePad({
    Key? key,
    //From Super
    required String name,
    FormFieldValidator<Uint8List>? validator,
    Uint8List? initialValue,
    InputDecoration decoration = const InputDecoration(),
    ValueChanged<Uint8List?>? onChanged,
    ValueTransformer<Uint8List?>? valueTransformer,
    bool enabled = true,
    FormFieldSetter<Uint8List>? onSaved,
    AutovalidateMode autovalidateMode = AutovalidateMode.disabled,
    VoidCallback? onReset,
    FocusNode? focusNode,
    this.backgroundColor = Colors.transparent,
    this.clearButtonText,
    this.width,
    this.height = 200,
    this.controller,
    this.border,
  }) : super(
          autovalidateMode: autovalidateMode,
          decoration: decoration,
          enabled: enabled,
          focusNode: focusNode,
          initialValue: initialValue,
          key: key,
          name: name,
          onChanged: onChanged,
          onReset: onReset,
          onSaved: onSaved,
          validator: validator,
          valueTransformer: valueTransformer,
          builder: (FormFieldState<Uint8List?> field) {
            final state = field as FormBuilderSignaturePadState;
            final theme = Theme.of(state.context);
            final localizations = MaterialLocalizations.of(state.context);
            final cancelButtonColor =
                state.enabled ? theme.colorScheme.error : theme.disabledColor;

            return InputDecorator(
              decoration: state.decoration,
              child: Column(
                children: <Widget>[
                  Container(
                    height: height,
                    width: width,
                    decoration: BoxDecoration(
                      border: border,
                      image:
                          (null != initialValue && initialValue == state.value)
                              ? DecorationImage(
                                  image: MemoryImage(state.value!),
                                )
                              : null,
                    ),
                    child: state.enabled
                        ? GestureDetector(
                            onHorizontalDragUpdate: (_) {},
                            onVerticalDragUpdate: (_) {},
                            child: Signature(
                              controller: state.effectiveController,
                              width: width,
                              height: height,
                              backgroundColor: backgroundColor,
                            ),
                          )
                        : null,
                  ),
                  Row(
                    children: <Widget>[
                      const Expanded(child: SizedBox()),
                      TextButton.icon(
                        onPressed: state.enabled
                            ? () {
                                state.effectiveController.clear();
                                field.didChange(null);
                              }
                            : null,
                        label: Text(
                          clearButtonText ?? localizations.cancelButtonLabel,
                          style: TextStyle(color: cancelButtonColor),
                        ),
                        icon: Icon(Icons.clear, color: cancelButtonColor),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );

  @override
  FormBuilderSignaturePadState createState() => FormBuilderSignaturePadState();
}

class FormBuilderSignaturePadState
    extends FormBuilderFieldState<FormBuilderSignaturePad, Uint8List> {
  late SignatureController _controller;

  SignatureController get effectiveController => _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? SignatureController();

    final onDrawEnd = _controller.onDrawEnd;

    _controller.onDrawEnd = () async {
      onDrawEnd?.call();
      focus();
      final val = await _getControllerValue();
      didChange(val);
    };

    SchedulerBinding.instance.addPostFrameCallback((Duration duration) async {
      // Get initialValue or if points are set, use the  points
      didChange(initialValue ?? await _getControllerValue());
    });
  }

  Future<Uint8List?> _getControllerValue() async {
    return await _controller.toPngBytes();
  }

  @override
  void reset() {
    _controller.clear();
    super.reset();
  }

  @override
  void dispose() {
    // Dispose the _controller when initState created it
    if (null == widget.controller) {
      _controller.dispose();
    }
    super.dispose();
  }
}
