import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/dday.dart';
import '../providers/dday_provider.dart';
import '../utils/constants.dart';
import '../widgets/common/custom_text_field.dart';
import '../widgets/common/custom_snackbar.dart';

class DDayFormScreen extends StatefulWidget {
  final DDay? dday;

  const DDayFormScreen({Key? key, this.dday}) : super(key: key);

  @override
  _DDayFormScreenState createState() => _DDayFormScreenState();
}

class _DDayFormScreenState extends State<DDayFormScreen> {
  final _titleController = TextEditingController();
  late DateTime _date;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    if (widget.dday != null) {
      _titleController.text = widget.dday!.title;
      _date = widget.dday!.date;
    } else {
      // 기본값은 오늘로부터 7일 후
      _date = DateTime.now().add(const Duration(days: 7));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: kAccentColor,
              onPrimary: Colors.white,
              surface: kSurfaceColor,
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: kSurfaceColor),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _date) {
      setState(() {
        _date = picked;
      });
    }
  }

  void _saveDDay() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final ddayProvider = Provider.of<DDayProvider>(context, listen: false);
    final userId = ddayProvider.getCurrentUserId();

    try {
      if (widget.dday == null) {
        // 새 디데이 추가
        final newDDay = DDay(
          id: ddayProvider.generateDDayId(),
          title: _titleController.text,
          date: _date,
          userId: userId!,
        );

        await ddayProvider.addDDay(newDDay);

        if (mounted) {
          CustomSnackbar.showSuccess(
            context: context,
            message: '디데이가 추가되었습니다',
          );
          Navigator.pop(context);
        }
      } else {
        // 기존 디데이 수정
        final updatedDDay = widget.dday!.copyWith(
          title: _titleController.text,
          date: _date,
        );

        await ddayProvider.updateDDay(updatedDDay);

        if (mounted) {
          CustomSnackbar.showSuccess(
            context: context,
            message: '디데이가 수정되었습니다',
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      CustomSnackbar.showError(
        context: context,
        message: '오류가 발생했습니다: $e',
      );
    }
  }

  void _deleteDDay() async {
    if (widget.dday == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurfaceColor,
        title: const Text(
          '디데이 삭제',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '이 디데이를 삭제하시겠습니까?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '삭제',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final ddayProvider = Provider.of<DDayProvider>(context, listen: false);
        await ddayProvider.deleteDDay(widget.dday!.id);

        if (mounted) {
          CustomSnackbar.showSuccess(
            context: context,
            message: '디데이가 삭제되었습니다',
          );
          Navigator.pop(context);
        }
      } catch (e) {
        CustomSnackbar.showError(
          context: context,
          message: '오류가 발생했습니다: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.dday != null;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: Text(
          isEditing ? '디데이 수정' : '디데이 추가',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteDDay,
            ),
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: _saveDDay,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kSpacing),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목 입력 필드
              const Text(
                '제목',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _titleController,
                labelText: '',
                hintText: '디데이 제목을 입력하세요',
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                textColor: Colors.white,
                hintColor: Colors.white.withValues(alpha: 0.5),
                fillColor: kSurfaceColor,
                borderRadius: BorderRadius.circular(8),
                borderColor: Colors.transparent,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '제목을 입력해주세요';
                  }
                  return null;
                },
                autofocus: true,
                enableSuggestions: true,
                autocorrect: false,
                onTap: () {
                  // 키보드 강제 표시
                  FocusScope.of(context).requestFocus(FocusNode());
                },
              ),
              const SizedBox(height: 24),

              // 날짜 선택 필드
              const Text(
                '날짜',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: kSurfaceColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('yyyy년 MM월 dd일 (E)', 'ko_KR').format(_date),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
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
