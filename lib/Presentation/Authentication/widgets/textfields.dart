import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hopper/Core/Consents/app_colors.dart';
import 'package:hopper/Core/Utility/app_images.dart';
import 'package:intl/intl.dart';


class CustomTextFields {
  static final CustomTextFields _singleton = CustomTextFields._internal();

  CustomTextFields._internal();

  static CustomTextFields get instance => _singleton;
  static dropDown({
    required String title,
    String? Function(String?)? validator,
    TextEditingController? controller,
    ValueChanged<String>? onChanged,
    required String hintText,
    VoidCallback? onTap,
    bool isReadOnly = true,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 8),
        TextFormField(
          cursorColor: AppColors.commonBlack,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: validator,
          controller: controller,
          style: TextStyle(
            color: Color(0xff111111),
            fontWeight: FontWeight.w500,
          ),
          readOnly: isReadOnly,
          onTap: onTap,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Color(0xff666666)),
            suffixIcon: suffixIcon,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red, width: 2),
            ),
          ),
        ),
      ],
    );
  }
  static datePickerField({
    required GlobalKey<FormState> formKey,
    String? Function(String?)? validator,
    required BuildContext context,
    required String title,
    ValueChanged<String>? onChanged,
    required String hintText,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 8),
        TextFormField(
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: onChanged,
          style: TextStyle(
            color: Color(0xff111111),
            fontWeight: FontWeight.w500,
          ),
          controller: controller,
          readOnly: true,
          validator: validator,
          decoration: InputDecoration(
            errorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 2),
            ),
            hintText: hintText,
            hintStyle: TextStyle(color: Color(0xff666666)),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xffF1F1F1)),
            ),
            suffixIcon: Icon(Icons.calendar_today, size: 20),
          ),
          onTap: () async {
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: ThemeData.light().copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppColors.commonBlack,
                      onPrimary: AppColors.commonWhite,
                      onSurface: AppColors.commonBlack,
                    ),
                    dialogBackgroundColor: AppColors.commonWhite,
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(
                        foregroundColor:
                        Colors.black, // ← makes Cancel/OK buttons black
                      ),
                    ),
                  ),
                  child: child!,
                );
              },
            );

            if (pickedDate != null) {
              DateTime today = DateTime.now();
              int age = today.year - pickedDate.year;
              if (today.month < pickedDate.month ||
                  (today.month == pickedDate.month &&
                      today.day < pickedDate.day)) {
                age--;
              }

              if (age < 18) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    duration: Duration(seconds: 2),
                    backgroundColor: Colors.red,
                    content: Text('You must be at least 18 years old'),
                  ),
                );
                controller.clear();
                formKey.currentState?.validate(); // ✅ forces re-validation
              } else {
                String formattedDate = DateFormat(
                  'd-MMMM-yyyy',
                ).format(pickedDate);
                controller.text = formattedDate;
                formKey.currentState?.validate(); // ✅ clears error
                if (onChanged != null) {
                  onChanged(formattedDate);
                }
              }
            }
          },
        ),
      ],
    );
  }
  static textField({
    required String tittle,
    GlobalKey<FormState>? formKey,
    required String hintText,
    TextEditingController? controller,
    TextInputType? type,
    ValueChanged<String>? onChanged,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,

    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tittle,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 8),
        TextFormField(
          cursorColor: Colors.black,

          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: (value) {
            // Call the passed onChanged if exists
            // if (onChanged != null) onChanged(value);
            // // Then trigger form validation if formKey is provided
            // formKey?.currentState?.validate();
          },
          inputFormatters: inputFormatters,
          keyboardType: type,
          controller: controller,
          readOnly: readOnly,
          style: TextStyle(
            color: Color(0xff111111),
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Color(0xff666666)),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xffF1F1F1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.black,
                width: 1.5,
              ), // BLACK BORDER
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.errorRed, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.errorRed, width: 1.5),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
  static mobileNumber({
    VoidCallback? onTap,
    Widget? suffixIcon,
    String? initialValue,
    bool readOnly = false,
    Widget? prefixIcon,
    required String title,
    TextEditingController? controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: Color(0xffF1F1F1)),
                child: TextField(
                  readOnly: true,

                  onTap: onTap,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    prefixIcon: prefixIcon,
                    suffixIcon: suffixIcon,
                  ),
                ),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              flex: 4,
              child: Container(
                decoration: BoxDecoration(color: Color(0xffF1F1F1)),
                child: TextFormField(
                  cursorColor: AppColors.commonBlack,
                  controller: controller,
                  initialValue: initialValue,
                  readOnly: readOnly,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    // focusedBorder: OutlineInputBorder(
                    //   borderSide: BorderSide(color: Colors.black, width: 1.5),
                    //   borderRadius: BorderRadius.circular(4),
                    // ),
                    hintText: '',
                    contentPadding: EdgeInsets.symmetric(horizontal: 20),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static plainTextField({
    VoidCallback? onTap,
    Widget? suffixIcon,
    String? initialValue,
    FocusNode? focusNode,
    bool readOnly = true,
    bool autofocus = false,
    String? leadingImage,
    double imgHeight = 10,
FontWeight fontWeight = FontWeight.w500,
    Widget? prefixIcon,
    TextStyle? Style,

    required String title,
    TextEditingController? controller,
    ValueChanged<String>? onChanged,
    TextStyle? hintStyle,
    Color containerColor = const Color(0xffF1F1F1),
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: containerColor,
      ),
      child: TextFormField(
        focusNode: focusNode,
        style: Style,
        cursorHeight: 16,
        autofocus: autofocus,
        onChanged: onChanged,
        onTap: onTap,
        controller: controller,
        initialValue: initialValue,
        readOnly: readOnly,
        cursorColor: AppColors.commonBlack,
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: EdgeInsets.symmetric(horizontal: imgHeight),
            child: Image.asset(
              leadingImage ?? AppImages.search,
              height: 5,
              width: 2,
            ),
          ),
          // focusedBorder: OutlineInputBorder(
          //   borderSide: BorderSide(color: Colors.black, width: 1.5),
          //   borderRadius: BorderRadius.circular(4),
          // ),
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(15),
          ),
          suffixIcon: suffixIcon,
          hintText: title,
          hintStyle:
              hintStyle ??
              TextStyle(
                fontWeight: fontWeight,
                color: AppColors.commonBlack,
                fontSize: 16,
              ),
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        ),
      ),
    );
  }

  static Text textWithStyles700(
    String text, {
    String? text1,
    double fontSize = 25,
    Color? color,
  }) {
    return Text(
      text + (text1 ?? ''),
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w700,
        fontSize: fontSize,
      ),
    );
  }

  static Text textWithStyles600(
    String text, {
    String? text1,
    double fontSize = 15,
    TextAlign textAlign = TextAlign.start,
    Color? color,
  }) {
    return Text(
      textAlign: textAlign,
      text + (text1 ?? ''),
      style: TextStyle(
        color: color,
        letterSpacing: 0.3,
        fontWeight: FontWeight.w600,
        fontSize: fontSize,
      ),
    );
  }

  static textWithStylesSmall(
    String text, {
    int? maxLines,
    String? text1,
    TextAlign textAlign = TextAlign.start,
    FontWeight? fontWeight,
    double fontSize = 13,
    Color? colors = Colors.black45,
  }) {
    return Text(
      overflow: TextOverflow.ellipsis,
      maxLines: maxLines,
      textAlign: textAlign,
      text + (text1 ?? ''),
      style: TextStyle(

        color: colors,
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
    );
  }

  static textAndField({
    required String tittle,
    GlobalKey<FormState>? formKey,
    required String hintText,
    double? fontSize,
    TextEditingController? controller,
    TextInputType? type,
    FontWeight? fontWeight = FontWeight.w400,
    int? maxLines,
    ValueChanged<String>? onChanged,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,

    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tittle,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 8),
        TextFormField(
          textInputAction: TextInputAction.next,
          maxLines: maxLines,
          cursorColor: Colors.black,

          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: (value) {
            // Call the passed onChanged if exists
            // if (onChanged != null) onChanged(value);
            // // Then trigger form validation if formKey is provided
            // formKey?.currentState?.validate();
          },
          inputFormatters: inputFormatters,
          keyboardType: type,
          controller: controller,
          readOnly: readOnly,
          style: TextStyle(
            color: Color(0xff111111),
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,

            hintText: hintText,
            hintStyle: TextStyle(
              fontSize: fontSize,
              color: Color(0xff666666),
              fontWeight: fontWeight,
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.containerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: AppColors.containerColor,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.black,
                width: 1.5,
              ), // BLACK BORDER
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.errorRed, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.errorRed, width: 1.5),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  static Widget textWithImage({
    required String text,
    String? rightImagePathText,
    VoidCallback? onTap,
    String? imagePath,
    String? rightImagePath,
    double imageSize = 16,
    double sizedBox = 5,
    double fontSize = 13,
    double rightTextFontSize = 15,
    TextAlign textAlign = TextAlign.start,
    FontWeight? fontWeight,
    Color? textColor = Colors.black,
    Color? colors = Colors.black45,
    Color? imageColors = Colors.black,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (imagePath != null)
            Image.asset(
              imagePath,
              height: imageSize,
              width: imageSize,
              color: imageColors,
            ),
          SizedBox(width: sizedBox),
          Flexible(
            child: Text(
              text,
              textAlign: textAlign,
              style: TextStyle(
                color: colors,
                fontSize: fontSize,
                fontWeight: fontWeight,
              ),
            ),
          ),
          SizedBox(width: 10),
          if (rightImagePath != null)
            Image.asset(rightImagePath, height: imageSize, width: imageSize),
          Text(
            rightImagePathText ?? '',
            style: TextStyle(
              fontFamily: "Roboto-normal",
              fontSize: rightTextFontSize,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
