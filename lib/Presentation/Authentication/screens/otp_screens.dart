import 'dart:async';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:flutter/material.dart';
import 'package:hopper/Core/Consents/app_colors.dart';
import 'package:hopper/Core/Consents/app_texts.dart';
import 'package:hopper/Core/Utility/app_buttons.dart';
import 'package:hopper/Presentation/Authentication/screens/permission_screens.dart';
import 'package:hopper/Presentation/Authentication/widgets/textfields.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class OtpScreens extends StatefulWidget {
  final String? countyCode;
  final String? mobileNumber;
  const OtpScreens({super.key, this.countyCode, this.mobileNumber});

  @override
  State<OtpScreens> createState() => _OtpScreensState();
}

class _OtpScreensState extends State<OtpScreens> {
  final formKey = GlobalKey<FormState>();
  TextEditingController otp = TextEditingController(text: "");
  bool isButtonDisabled = false;
  String verifyCode = '';
  StreamController<ErrorAnimationType>? errorController;
  String? otpError;
  late Timer _timer;
  int _start = 30;

  @override
  void initState() {
    super.initState();

    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    otp.dispose();
    super.dispose();
  }

  void _resendOtp() {
    setState(() {
      _start = 30;
    });
    _startTimer();
  }

  void _startTimer() {
    // _sendOtp();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_start > 0) {
        setState(() {
          _start--;
        });
      } else {
        _timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      AppButtons.backButton(context: context),
                      SizedBox(height: 25),
                      CustomTextFields.textWithStyles700(
                        AppTexts.otpText,
                        text1: ' ${widget.countyCode} ${widget.mobileNumber}',
                      ),
                      SizedBox(height: 30),

                      Form(
                        key: formKey,
                        child: PinCodeTextField(
                          autoFocus: true,
                          appContext: context,
                          // pastedTextStyle: TextStyle(
                          //   color: Colors.green.shade600,
                          //   fontWeight: FontWeight.bold,
                          // ),
                          length: 4,

                          // obscureText: true,
                          // obscuringCharacter: '*',
                          // obscuringWidget: const FlutterLogo(size: 24,),
                          blinkWhenObscuring: true,
                          mainAxisAlignment: MainAxisAlignment.start,
                          autoDisposeControllers: false,
                          animationType: AnimationType.fade,

                          // validator: (v) {
                          //   if (v == null || v.length != 4)
                          //     return 'Enter valid 4-digit OTP';
                          //   return null;
                          // },
                          pinTheme: PinTheme(
                            shape: PinCodeFieldShape.box,
                            borderRadius: BorderRadius.circular(5.sp),
                            fieldHeight: 48.sp,
                            fieldWidth: 48.sp,
                            selectedColor: AppColors.commonBlack,
                            activeColor: AppColors.containerColor,
                            activeFillColor: AppColors.containerColor,
                            inactiveColor: AppColors.containerColor,
                            selectedFillColor: AppColors.containerColor,
                            fieldOuterPadding: EdgeInsets.symmetric(
                              horizontal: 5,
                            ),
                            inactiveFillColor: AppColors.containerColor,
                          ),
                          cursorColor: Colors.black,
                          animationDuration: const Duration(milliseconds: 300),
                          enableActiveFill: true,
                          errorAnimationController: errorController,
                          controller: otp,
                          keyboardType: TextInputType.number,
                          boxShadows: const [
                            BoxShadow(
                              offset: Offset(0, 1),
                              color: Colors.black12,
                              blurRadius: 5,
                            ),
                          ],
                          // validator: (value) {
                          //   if (value == null || value.length != 4) {
                          //     return 'Please enter a valid 4-digit OTP';
                          //   }
                          //   return null;
                          // },
                          // onCompleted: (value) async {},
                          onChanged: (value) {
                            debugPrint(value);

                            verifyCode = value;
                            if (value.length == 4 && otpError != null) {
                              setState(() {
                                otpError = null;
                              });
                            }
                          },
                          beforeTextPaste: (text) {
                            debugPrint("Allowing to paste $text");
                            return true;
                          },
                        ),
                      ),
                      if (otpError != null)
                        Text(
                          otpError!,
                          style: TextStyle(color: Colors.red, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      SizedBox(height: 20),

                      _start > 0
                          ? Text(
                            '${AppTexts.youWillGetCodeBySmsIn} (00:${_start.toString().padLeft(2, '0')})',
                          )
                          : GestureDetector(
                            onTap: _resendOtp,
                            child: Text(
                              AppTexts.resendCode,
                              style: TextStyle(
                                color: AppColors.resendBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
              AppButtons.button(
                onTap: () {
                  if (otp.text.length != 4) {
                    errorController?.add(ErrorAnimationType.shake);
                    setState(() {
                      otpError = 'Please enter a valid 4-digit OTP';
                      isButtonDisabled = false;
                    });
                    return;
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PermissionScreens(),
                      ),
                    );
                  }

                  // if (otp.text.length != 4) {
                  //   errorController?.add(ErrorAnimationType.shake);
                  //   setState(() {
                  //     otpError = 'Please enter a valid 4-digit OTP';
                  //     isButtonDisabled = false;
                  //   });
                  //   return;
                  // }
                },
                text: AppTexts.verify,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
