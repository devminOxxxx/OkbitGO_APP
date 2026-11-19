import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String labelText;
  final String hintText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final Function(String)? onSubmitted;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;
  final bool autofocus;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool filled;
  final Color? fillColor;
  final Color? textColor;
  final Color? labelColor;
  final Color? hintColor;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final EdgeInsetsGeometry? contentPadding;
  final bool enableSuggestions;
  final bool autocorrect;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool showCursor;
  final double? cursorHeight;
  final Color? cursorColor;
  final BorderRadius? borderRadius;
  final Function()? onTap;

  const CustomTextField({
    Key? key,
    required this.controller,
    this.focusNode,
    required this.labelText,
    this.hintText = '',
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.obscureText = false,
    this.onSubmitted,
    this.onChanged,
    this.validator,
    this.autofocus = false,
    this.prefixIcon,
    this.suffixIcon,
    this.filled = true,
    this.fillColor,
    this.textColor,
    this.labelColor,
    this.hintColor,
    this.borderColor,
    this.focusedBorderColor,
    this.contentPadding,
    this.enableSuggestions = true,
    this.autocorrect = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.showCursor = true,
    this.cursorHeight,
    this.cursorColor,
    this.borderRadius,
    this.onTap,
  }) : super(key: key);

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();

    // 자동 포커스 설정
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(_focusNode);
      });
    }
  }

  @override
  void dispose() {
    // 외부에서 제공된 focusNode가 아닌 경우에만 dispose
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  // 텍스트를 저장하고 컨트롤러를 초기화하는 함수
  void _submitAndClear() {
    final text = widget.controller.text;
    if (text.isNotEmpty && widget.onSubmitted != null) {
      widget.onSubmitted!(text);
    }
    widget.controller.clear();
    // 키보드 유지를 위해 포커스 유지
    FocusScope.of(context).requestFocus(_focusNode);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.suffixIcon,
        filled: widget.filled,
        fillColor: widget.fillColor ?? theme.inputDecorationTheme.fillColor,
        labelStyle: TextStyle(
          color:
              widget.labelColor ?? theme.inputDecorationTheme.labelStyle?.color,
        ),
        hintStyle: TextStyle(
          color:
              widget.hintColor ?? theme.inputDecorationTheme.hintStyle?.color,
        ),
        contentPadding: widget.contentPadding ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
          borderSide: BorderSide(
            color: widget.borderColor ??
                theme.inputDecorationTheme.border?.borderSide.color ??
                Colors.grey,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
          borderSide: BorderSide(
            color: widget.borderColor ??
                theme.inputDecorationTheme.enabledBorder?.borderSide.color ??
                Colors.grey,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
          borderSide: BorderSide(
            color: widget.focusedBorderColor ?? theme.primaryColor,
            width: 2.0,
          ),
        ),
      ),
      style: TextStyle(
        color: widget.textColor ?? theme.textTheme.bodyMedium?.color,
      ),
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      obscureText: widget.obscureText,
      onFieldSubmitted: (value) {
        if (widget.textInputAction == TextInputAction.done) {
          _submitAndClear();
        } else if (widget.onSubmitted != null) {
          widget.onSubmitted!(value);
        }
      },
      onChanged: widget.onChanged,
      validator: widget.validator,
      autofocus: widget.autofocus,
      enableInteractiveSelection: true,
      enableSuggestions: widget.enableSuggestions,
      autocorrect: widget.autocorrect,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      showCursor: widget.showCursor,
      cursorHeight: widget.cursorHeight,
      cursorColor: widget.cursorColor ?? theme.primaryColor,
      onTap: widget.onTap,
    );
  }
}
