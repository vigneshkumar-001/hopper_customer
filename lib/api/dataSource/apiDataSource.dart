import 'dart:convert';
import 'dart:io';

import 'package:hopper/Core/Consents/app_logger.dart';
import 'package:hopper/Presentation/Authentication/models/login_response.dart';
import 'package:hopper/Presentation/Authentication/models/otp_response.dart';
import 'package:hopper/Presentation/BookRide/Models/create_booking_model.dart';
import 'package:hopper/Presentation/BookRide/Models/driver_search_models.dart';
import 'package:hopper/Presentation/BookRide/Models/send_driver_request_models.dart';
import 'package:hopper/Presentation/OnBoarding/models/address_models.dart';
import 'package:hopper/Presentation/OnBoarding/models/confrom_package_response.dart';
import 'package:hopper/Presentation/OnBoarding/models/package_details_response.dart';

import 'package:hopper/api/repository/api_consents.dart';

import 'package:hopper/api/repository/request.dart';

import '../../Presentation/OnBoarding/models/send_package_driver_response.dart';
import '../../Presentation/OnBoarding/models/user_image_models.dart';
import '../repository/failure.dart';
import 'package:dio/dio.dart';
import 'package:dartz/dartz.dart';

abstract class BaseApiDataSource {
  Future<Either<Failure, LoginResponse>> mobileNumberLogin(
    String mobileNumber,
    String countryCode,
  );
}

class ApiDataSource extends BaseApiDataSource {
  @override
  Future<Either<Failure, LoginResponse>> mobileNumberLogin(
    String mobileNumber,
    String countryCode,
  ) async {
    try {
      String url = ApiConsents.signIn;
      final String phone = countryCode + mobileNumber;
      dynamic response = await Request.sendRequest(
        url,
        {"phone": phone},
        'Post',
        false,
      );
      if (response is! DioException && response.statusCode == 200) {
        if (response.data['status'] == 200) {
          return Right(LoginResponse.fromJson(response.data));
        } else {
          return Left(ServerFailure(response.data['message']));
        }
      } else {
        return Left(ServerFailure((response as DioException).message ?? ""));
      }
    } catch (e) {
      return Left(ServerFailure(''));
    }
  }

  Future<Either<Failure, OtpResponse>> otpVerify(
    String mobileNumber,
    String countryCode,
  ) async {
    try {
      String url = ApiConsents.verifyOtp;

      dynamic response = await Request.sendRequest(
        url,
        {"phone": mobileNumber, "otp": countryCode},
        'Post',
        false,
      );
      if (response is! DioException && response.statusCode == 200) {
        if (response.data['status'] == 200) {
          return Right(OtpResponse.fromJson(response.data));
        } else {
          return Left(ServerFailure(response.data['message']));
        }
      } else {
        return Left(ServerFailure((response as DioException).message ?? ""));
      }
    } catch (e) {
      return Left(ServerFailure(''));
    }
  }

  Future<Either<Failure, LoginResponse>> resendOtp(
    String mobileNumber,
    String countryCode,
  ) async {
    try {
      String url = ApiConsents.resendOtp;
      final String phone = countryCode + mobileNumber;
      AppLogger.log.i(phone);
      dynamic response = await Request.sendRequest(
        url,
        {"phone": phone},

        'Post',
        false,
      );
      if (response is! DioException && response.statusCode == 200) {
        if (response.data['status'] == 200) {
          return Right(LoginResponse.fromJson(response.data));
        } else {
          return Left(ServerFailure(response.data['message']));
        }
      } else {
        return Left(ServerFailure((response as DioException).message ?? ""));
      }
    } catch (e) {
      return Left(ServerFailure(''));
    }
  }

  Future<Either<Failure, DriverSearchModels>> getDriverSearch({
    required double pickupLat,
    required double pickupLng,
    required double dropLat,
    required double dropLng,
  }) async {
    try {
      final url = ApiConsents.driverSearch(
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        dropLat: dropLat,
        dropLng: dropLng,
      );
      AppLogger.log.i(url);

      dynamic response = await Request.sendGetRequest(url, {}, 'GET', false);

      if (response.statusCode == 200) {
        if (response.data['status'] == 200) {
          return Right(DriverSearchModels.fromJson(response.data));
        } else {
          return Left(
            ServerFailure(response.data['message'] ?? "Login failed"),
          );
        }
      } else if (response is Response) {
        return Left(
          ServerFailure(response.data['message'] ?? "Unexpected error"),
        );
      } else {
        return Left(ServerFailure("Unknown error occurred"));
      }
    } catch (e) {
      AppLogger.log.e(e);
      return Left(ServerFailure('Something went wrong'));
    }
  }

  Future<Either<Failure, CreateBookingModel>> carBookingCar({
    required double fromLatitude,
    required double fromLongitude,
    required double toLatitude,
    required double toLongitude,
    required String customerId,
  }) async {
    try {
      final url = ApiConsents.createBooking;
      AppLogger.log.i(url);

      dynamic response = await Request.sendRequest(
        url,
        {
          "fromLatitude": fromLatitude,
          "fromLongitude": fromLongitude,
          "toLatitude": toLatitude,
          "toLongitude": toLongitude,

          "sharedBooking": false,
          "sharedCount": 1,
        },
        'Post',
        false,
      );
      if (response.statusCode == 200) {
        if (response.data['status'] == 200) {
          return Right(CreateBookingModel.fromJson(response.data));
        } else {
          return Left(ServerFailure(response.data['message'] ?? " "));
        }
      } else if (response is Response) {
        return Left(
          ServerFailure(response.data['message'] ?? "Unexpected error"),
        );
      } else {
        return Left(ServerFailure("Unknown error occurred"));
      }
    } catch (e) {
      AppLogger.log.e(e);
      return Left(ServerFailure('Something went wrong'));
    }
  }

  Future<Either<Failure, SendDriverRequestModels>> sendDriverRequest({
    required double pickupLatitude,
    required double pickupLongitude,
    required double dropLatitude,
    required double dropLongitude,
    required String bookingId,
    required String carType,
  }) async {
    try {
      final url = ApiConsents.sendDriverRequest;
      AppLogger.log.i(url);
      final carTypes = carType == 'Sedan' ? 'sedan' : 'luxury';

      dynamic response = await Request.sendRequest(
        url,
        {
          "bookingId": bookingId,
          "pickupLatitude": pickupLatitude,
          "pickupLongitude": pickupLongitude,
          "dropLatitude": dropLatitude,
          "dropLongitude": dropLongitude,
          "carType": carTypes,
        },
        'Post',
        false,
      );
      if (response.statusCode == 200) {
        if (response.data['status'] == 200) {
          return Right(SendDriverRequestModels.fromJson(response.data));
        } else {
          return Left(ServerFailure(response.data['message'] ?? " "));
        }
      } else if (response is Response) {
        return Left(
          ServerFailure(response.data['message'] ?? "Unexpected error"),
        );
      } else {
        return Left(ServerFailure("Unknown error occurred"));
      }
    } catch (e) {
      AppLogger.log.e(e);
      return Left(ServerFailure('Something went wrong'));
    }
  }

  Future<Either<Failure, SendDriverRequestModels>> cancelRide({
    required String bookingId,
    required String selectedReason,
  }) async {
    try {
      final url = ApiConsents.cancelRide(bookingId: bookingId);
      AppLogger.log.i(url);

      dynamic response = await Request.sendRequest(
        url,
        {"rejectedReason": selectedReason},
        'Post',
        true,
      );
      if (response.statusCode == 200) {
        if (response.data['status'] == 200) {
          return Right(SendDriverRequestModels.fromJson(response.data));
        } else {
          return Left(ServerFailure(response.data['message'] ?? " "));
        }
      } else if (response is Response) {
        return Left(
          ServerFailure(response.data['message'] ?? "Unexpected error"),
        );
      } else {
        return Left(ServerFailure("Unknown error occurred"));
      }
    } catch (e) {
      AppLogger.log.e(e);
      return Left(ServerFailure('Something went wrong'));
    }
  }

  Future<Either<Failure, SendDriverRequestModels>> starRating({
    required String bookingId,
    required String selectedReason,
  }) async {
    try {
      final url = ApiConsents.rateDriver(bookingId: bookingId);
      AppLogger.log.i(url);

      dynamic response = await Request.sendRequest(
        url,
        {"rating": selectedReason, "review": ''},
        'Post',
        false,
      );
      if (response.statusCode == 200) {
        if (response.data['status'] == 200) {
          return Right(SendDriverRequestModels.fromJson(response.data));
        } else {
          return Left(ServerFailure(response.data['message'] ?? " "));
        }
      } else if (response is Response) {
        return Left(
          ServerFailure(response.data['message'] ?? "Unexpected error"),
        );
      } else {
        return Left(ServerFailure("Unknown error occurred"));
      }
    } catch (e) {
      AppLogger.log.e(e);
      return Left(ServerFailure('Something went wrong'));
    }
  }

  Future<Either<Failure, PackageDetailsResponse>> packageAddressDetails({
    required AddressModel senderData,
    required AddressModel receiverData,
  }) async {
    try {
      final url = ApiConsents.createBooking;
      AppLogger.log.i(url);
      final data = {
        "fromLatitude": senderData.latitude,
        "fromLongitude": senderData.longitude,
        "pickupAddress": senderData.address,
        "fromContact_name": senderData.name,
        "fromContact_phone": senderData.phone,
        "toLatitude": receiverData.latitude,
        "toLongitude": receiverData.longitude,
        "dropAddress": receiverData.address,
        "toContact_name": receiverData.name,
        "toContact_phone": receiverData.phone,
        "parcel_type": "Documents",
        "description": "Important legal papers",
        "delivery_instruction": "Deliver at reception desk",
        "address_type": "Work",
        "rideType": "Bike",
        "bookingType": "Parcel",
        "maxWeight": "50",
      };

      dynamic response = await Request.sendRequest(url, data, 'Post', false);
      if (response.statusCode == 200) {
        if (response.data['status'] == 200) {
          return Right(PackageDetailsResponse.fromJson(response.data));
        } else {
          return Left(ServerFailure(response.data['message'] ?? " "));
        }
      } else if (response is Response) {
        return Left(
          ServerFailure(response.data['message'] ?? "Unexpected error"),
        );
      } else {
        return Left(ServerFailure("Unknown error occurred"));
      }
    } catch (e) {
      AppLogger.log.e(e);
      return Left(ServerFailure('Something went wrong'));
    }
  }

  Future<Either<Failure, ConfirmPackageResponse>> confirmPackageScreen({
    required String bookingId,
  }) async {
    try {
      final url = ApiConsents.confirmBooking;
      AppLogger.log.i(url);

      dynamic response = await Request.sendRequest(
        url,
        {"bookingId": bookingId},
        'Post',
        false,
      );
      if (response.statusCode == 200) {
        if (response.data['success'] == true) {
          return Right(ConfirmPackageResponse.fromJson(response.data));
        } else {
          return Left(ServerFailure(response.data['message'] ?? " "));
        }
      } else if (response is Response) {
        return Left(
          ServerFailure(response.data['message'] ?? "Unexpected error"),
        );
      } else {
        return Left(ServerFailure("Unknown error occurred"));
      }
    } catch (e) {
      AppLogger.log.e(e);
      return Left(ServerFailure('Something went wrong'));
    }
  }

  Future<Either<Failure, SendPackageDriverResponse>> sendPackageDriverRequest({
    required String bookingId,
    required AddressModel senderData,
    required AddressModel receiverData,
  }) async {
    try {
      final url = ApiConsents.sendDriverRequest;
      final data = {
        "bookingId": bookingId,
        "pickupLatitude": senderData.latitude,
        "pickupLongitude": senderData.longitude,
        "dropLatitude": receiverData.latitude,
        "dropLongitude": receiverData.longitude,
      };

      AppLogger.log.i(url);
      dynamic response = await Request.sendRequest(url, data, 'Post', false);
      if (response.statusCode == 200) {
        return Right(SendPackageDriverResponse.fromJson(response.data));
        // if (response.data['success'] == 200) {
        //   return Right(SendDriverRequestModels.fromJson(response.data));
        // } else {
        //   return Left(ServerFailure(response.data['message'] ?? " "));
        // }
      } else if (response is Response) {
        return Left(
          ServerFailure(response.data['message'] ?? "Unexpected error"),
        );
      } else {
        return Left(ServerFailure("Unknown error occurred"));
      }
    } catch (e) {
      AppLogger.log.e(e);
      return Left(ServerFailure('Something went wrong'));
    }
  }

  Future<Either<Failure, UserImageModels>> userProfileUpload({
    required File imageFile,
  }) async {
    try {
      if (!await imageFile.exists()) {
        return Left(ServerFailure('Image file does not exist.'));
      }

      String url = ApiConsents.userImageUpload;
      FormData formData = FormData.fromMap({
        'images': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      final response = await Request.formData(url, formData, 'POST', true);
      Map<String, dynamic> responseData =
      jsonDecode(response.data) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        if (responseData['status'] == true) {
          return Right(UserImageModels.fromJson(responseData));
        } else {
          return Left(ServerFailure(responseData['message']));
        }
      } else if (response is Response && response.statusCode == 409) {
        return Left(ServerFailure(responseData['message']));
      } else if (response is Response) {
        return Left(ServerFailure(responseData['message'] ?? "Unknown error"));
      } else {
        return Left(ServerFailure("Unexpected error"));
      }
    } catch (e) {
      AppLogger.log.e(e);
      return Left(ServerFailure('Something went wrong'));
    }
  }

}
