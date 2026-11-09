import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi')
  ];

  /// No description provided for @commonCancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get commonCancel;

  /// No description provided for @commonConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận'**
  String get commonConfirm;

  /// No description provided for @commonSave.
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In vi, this message translates to:
  /// **'Xóa'**
  String get commonDelete;

  /// No description provided for @commonSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Thành công'**
  String get commonSuccess;

  /// No description provided for @commonError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi'**
  String get commonError;

  /// No description provided for @commonRetry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get commonRetry;

  /// No description provided for @commonLoading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải...'**
  String get commonLoading;

  /// No description provided for @commonSearch.
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm'**
  String get commonSearch;

  /// No description provided for @commonClose.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get commonClose;

  /// No description provided for @commonBack.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get commonBack;

  /// No description provided for @commonNext.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get commonNext;

  /// No description provided for @commonGetStarted.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu ngay'**
  String get commonGetStarted;

  /// No description provided for @commonSeeAll.
  ///
  /// In vi, this message translates to:
  /// **'Xem tất cả'**
  String get commonSeeAll;

  /// No description provided for @commonAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get commonAll;

  /// No description provided for @commonViewDetail.
  ///
  /// In vi, this message translates to:
  /// **'Xem chi tiết'**
  String get commonViewDetail;

  /// No description provided for @commonApply.
  ///
  /// In vi, this message translates to:
  /// **'Áp dụng'**
  String get commonApply;

  /// No description provided for @commonEdit.
  ///
  /// In vi, this message translates to:
  /// **'Chỉnh sửa'**
  String get commonEdit;

  /// No description provided for @commonShare.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ'**
  String get commonShare;

  /// No description provided for @commonCopy.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép'**
  String get commonCopy;

  /// No description provided for @commonCopied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép vào bộ nhớ tạm'**
  String get commonCopied;

  /// No description provided for @commonUnderDevelopment.
  ///
  /// In vi, this message translates to:
  /// **'Tính năng đang được phát triển'**
  String get commonUnderDevelopment;

  /// No description provided for @commonNotification.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo'**
  String get commonNotification;

  /// No description provided for @commonQuantity.
  ///
  /// In vi, this message translates to:
  /// **'Số lượng'**
  String get commonQuantity;

  /// No description provided for @commonNote.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú'**
  String get commonNote;

  /// No description provided for @navHome.
  ///
  /// In vi, this message translates to:
  /// **'Trang chủ'**
  String get navHome;

  /// No description provided for @navMenu.
  ///
  /// In vi, this message translates to:
  /// **'Thực đơn'**
  String get navMenu;

  /// No description provided for @navOffer.
  ///
  /// In vi, this message translates to:
  /// **'Cửa hàng'**
  String get navOffer;

  /// No description provided for @navProfile.
  ///
  /// In vi, this message translates to:
  /// **'Hồ sơ'**
  String get navProfile;

  /// No description provided for @navMore.
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get navMore;

  /// No description provided for @navCart.
  ///
  /// In vi, this message translates to:
  /// **'Giỏ hàng'**
  String get navCart;

  /// No description provided for @navMyOrder.
  ///
  /// In vi, this message translates to:
  /// **'Đơn hàng của tôi'**
  String get navMyOrder;

  /// No description provided for @navNotifications.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo'**
  String get navNotifications;

  /// No description provided for @navInbox.
  ///
  /// In vi, this message translates to:
  /// **'Voucher'**
  String get navInbox;

  /// No description provided for @orderModeQuickStop.
  ///
  /// In vi, this message translates to:
  /// **'Ghé mua'**
  String get orderModeQuickStop;

  /// No description provided for @orderModePreOrder.
  ///
  /// In vi, this message translates to:
  /// **'Đặt trước'**
  String get orderModePreOrder;

  /// No description provided for @orderModeDineIn.
  ///
  /// In vi, this message translates to:
  /// **'Ăn tại quán'**
  String get orderModeDineIn;

  /// No description provided for @orderModeReserveTable.
  ///
  /// In vi, this message translates to:
  /// **'Đặt bàn'**
  String get orderModeReserveTable;

  /// No description provided for @orderStatusUnpaid.
  ///
  /// In vi, this message translates to:
  /// **'Chờ thanh toán'**
  String get orderStatusUnpaid;

  /// No description provided for @orderStatusAwaitingConfirmation.
  ///
  /// In vi, this message translates to:
  /// **'Chờ xác nhận'**
  String get orderStatusAwaitingConfirmation;

  /// No description provided for @orderStatusConfirmed.
  ///
  /// In vi, this message translates to:
  /// **'Đã xác nhận'**
  String get orderStatusConfirmed;

  /// No description provided for @orderStatusPreparing.
  ///
  /// In vi, this message translates to:
  /// **'Đang chuẩn bị'**
  String get orderStatusPreparing;

  /// No description provided for @orderStatusReadyForPickup.
  ///
  /// In vi, this message translates to:
  /// **'Sẵn sàng lấy'**
  String get orderStatusReadyForPickup;

  /// No description provided for @orderStatusCompleted.
  ///
  /// In vi, this message translates to:
  /// **'Đã hoàn tất'**
  String get orderStatusCompleted;

  /// No description provided for @orderStatusCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Đã hủy'**
  String get orderStatusCancelled;

  /// No description provided for @reservationStatusPending.
  ///
  /// In vi, this message translates to:
  /// **'Chờ xác nhận'**
  String get reservationStatusPending;

  /// No description provided for @reservationStatusConfirmed.
  ///
  /// In vi, this message translates to:
  /// **'Đã xác nhận'**
  String get reservationStatusConfirmed;

  /// No description provided for @reservationStatusCompleted.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tất'**
  String get reservationStatusCompleted;

  /// No description provided for @reservationStatusCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Đã hủy'**
  String get reservationStatusCancelled;

  /// No description provided for @paymentMethodCash.
  ///
  /// In vi, this message translates to:
  /// **'Tiền mặt khi nhận món'**
  String get paymentMethodCash;

  /// No description provided for @paymentMethodVietQR.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển khoản VietQR'**
  String get paymentMethodVietQR;

  /// No description provided for @paymentMethodVNPay.
  ///
  /// In vi, this message translates to:
  /// **'Ví điện tử VNPAY'**
  String get paymentMethodVNPay;

  /// No description provided for @paymentMethodMoMo.
  ///
  /// In vi, this message translates to:
  /// **'Ví điện tử MoMo'**
  String get paymentMethodMoMo;

  /// No description provided for @onboardingTitle1.
  ///
  /// In vi, this message translates to:
  /// **'Món Ngon Tiện Đường'**
  String get onboardingTitle1;

  /// No description provided for @onboardingSubtitle1.
  ///
  /// In vi, this message translates to:
  /// **'Khám phá hàng trăm quán ngon chuẩn vị,\nđặt trước tiện lợi ngay trên lộ trình di chuyển'**
  String get onboardingSubtitle1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In vi, this message translates to:
  /// **'Nóng Hổi Chuẩn Giờ'**
  String get onboardingTitle2;

  /// No description provided for @onboardingSubtitle2.
  ///
  /// In vi, this message translates to:
  /// **'Quán chuẩn bị món vừa xong đúng lúc bạn ghé lấy,\ntối ưu thời gian, không cần chờ đợi'**
  String get onboardingSubtitle2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In vi, this message translates to:
  /// **'Lộ Trình Thông Minh'**
  String get onboardingTitle3;

  /// No description provided for @onboardingSubtitle3.
  ///
  /// In vi, this message translates to:
  /// **'Định vị điểm đến và theo dõi đơn hàng thời gian thực,\nsẵn sàng trên mọi cung đường của bạn'**
  String get onboardingSubtitle3;

  /// No description provided for @onboardingPinStart.
  ///
  /// In vi, this message translates to:
  /// **'Điểm đi'**
  String get onboardingPinStart;

  /// No description provided for @onboardingPinStore.
  ///
  /// In vi, this message translates to:
  /// **'Quán ăn'**
  String get onboardingPinStore;

  /// No description provided for @onboardingPinHome.
  ///
  /// In vi, this message translates to:
  /// **'Về nhà'**
  String get onboardingPinHome;

  /// No description provided for @onboardingStorePickup1Min.
  ///
  /// In vi, this message translates to:
  /// **'Ghé lấy 1p'**
  String get onboardingStorePickup1Min;

  /// No description provided for @onboardingStorePickupDone.
  ///
  /// In vi, this message translates to:
  /// **'✔ Đã lấy món'**
  String get onboardingStorePickupDone;

  /// No description provided for @authWelcome.
  ///
  /// In vi, this message translates to:
  /// **'Chào mừng'**
  String get authWelcome;

  /// No description provided for @authWelcomeBack.
  ///
  /// In vi, this message translates to:
  /// **'Chào mừng trở lại'**
  String get authWelcomeBack;

  /// No description provided for @authLogin.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get authLogin;

  /// No description provided for @authSignUp.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký'**
  String get authSignUp;

  /// No description provided for @authLogout.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất'**
  String get authLogout;

  /// No description provided for @authLoginTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get authLoginTitle;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập để khám phá hàng ngàn quán ngon'**
  String get authLoginSubtitle;

  /// No description provided for @authSignUpTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo tài khoản mới'**
  String get authSignUpTitle;

  /// No description provided for @authSignUpSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký để khám phá hàng ngàn quán ngon'**
  String get authSignUpSubtitle;

  /// No description provided for @authFullName.
  ///
  /// In vi, this message translates to:
  /// **'Họ và tên'**
  String get authFullName;

  /// No description provided for @authYourEmail.
  ///
  /// In vi, this message translates to:
  /// **'Email của bạn'**
  String get authYourEmail;

  /// No description provided for @authAccountOrEmail.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản hoặc Email'**
  String get authAccountOrEmail;

  /// No description provided for @authPhone.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại'**
  String get authPhone;

  /// No description provided for @authAddress.
  ///
  /// In vi, this message translates to:
  /// **'Địa chỉ'**
  String get authAddress;

  /// No description provided for @authPassword.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu'**
  String get authPassword;

  /// No description provided for @authConfirmPassword.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận mật khẩu'**
  String get authConfirmPassword;

  /// No description provided for @authForgotPassword.
  ///
  /// In vi, this message translates to:
  /// **'Quên mật khẩu?'**
  String get authForgotPassword;

  /// No description provided for @authForgotPasswordSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhập email của bạn để nhận mã xác thực đặt lại mật khẩu tài khoản'**
  String get authForgotPasswordSubtitle;

  /// No description provided for @authSendVerificationCode.
  ///
  /// In vi, this message translates to:
  /// **'Gửi mã xác thực'**
  String get authSendVerificationCode;

  /// No description provided for @authBackTo.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại '**
  String get authBackTo;

  /// No description provided for @authResetCodeSentSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Mã đặt lại mật khẩu đã được gửi đến email của bạn!'**
  String get authResetCodeSentSuccess;

  /// No description provided for @authRequestFailed.
  ///
  /// In vi, this message translates to:
  /// **'Gửi yêu cầu thất bại'**
  String get authRequestFailed;

  /// No description provided for @authOtpTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xác thực mã OTP'**
  String get authOtpTitle;

  /// No description provided for @authOtpSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Mã xác thực đã được gửi tới email {email}.\nVui lòng nhập mã gồm 6 chữ số bên dưới:'**
  String authOtpSubtitle(String email);

  /// No description provided for @authOtpConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận mã'**
  String get authOtpConfirm;

  /// No description provided for @authOtpDidNotReceive.
  ///
  /// In vi, this message translates to:
  /// **'Chưa nhận được mã? '**
  String get authOtpDidNotReceive;

  /// No description provided for @authOtpResend.
  ///
  /// In vi, this message translates to:
  /// **'Gửi lại'**
  String get authOtpResend;

  /// No description provided for @authOtpInput6Digits.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập đủ 6 chữ số mã OTP'**
  String get authOtpInput6Digits;

  /// No description provided for @authOtpResentSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Mã xác thực đã được gửi lại vào email của bạn'**
  String get authOtpResentSuccess;

  /// No description provided for @authNewPasswordTitle.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu mới'**
  String get authNewPasswordTitle;

  /// No description provided for @authNewPasswordSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập mật khẩu mới cho tài khoản của bạn'**
  String get authNewPasswordSubtitle;

  /// No description provided for @authNewPasswordLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu mới'**
  String get authNewPasswordLabel;

  /// No description provided for @authConfirmNewPasswordLabel.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận mật khẩu mới'**
  String get authConfirmNewPasswordLabel;

  /// No description provided for @authChangePasswordButton.
  ///
  /// In vi, this message translates to:
  /// **'Đổi mật khẩu'**
  String get authChangePasswordButton;

  /// No description provided for @authNewPasswordRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập đầy đủ mật khẩu mới và xác nhận mật khẩu'**
  String get authNewPasswordRequired;

  /// No description provided for @authChangePasswordSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đổi mật khẩu thành công! Vui lòng đăng nhập lại.'**
  String get authChangePasswordSuccess;

  /// No description provided for @authChangePasswordFailed.
  ///
  /// In vi, this message translates to:
  /// **'Đổi mật khẩu thất bại'**
  String get authChangePasswordFailed;

  /// No description provided for @authResetPassword.
  ///
  /// In vi, this message translates to:
  /// **'Đặt lại mật khẩu'**
  String get authResetPassword;

  /// No description provided for @authRememberMe.
  ///
  /// In vi, this message translates to:
  /// **'Ghi nhớ đăng nhập'**
  String get authRememberMe;

  /// No description provided for @authSessionExpired.
  ///
  /// In vi, this message translates to:
  /// **'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại.'**
  String get authSessionExpired;

  /// No description provided for @authOrLoginWith.
  ///
  /// In vi, this message translates to:
  /// **'HOẶC ĐĂNG NHẬP VỚI'**
  String get authOrLoginWith;

  /// No description provided for @authLoginGoogle.
  ///
  /// In vi, this message translates to:
  /// **'Google'**
  String get authLoginGoogle;

  /// No description provided for @authLoginApple.
  ///
  /// In vi, this message translates to:
  /// **'Apple'**
  String get authLoginApple;

  /// No description provided for @authDontHaveAccount.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có tài khoản? '**
  String get authDontHaveAccount;

  /// No description provided for @authAlreadyHaveAccount.
  ///
  /// In vi, this message translates to:
  /// **'Đã có tài khoản? '**
  String get authAlreadyHaveAccount;

  /// No description provided for @authRegisterNow.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký ngay'**
  String get authRegisterNow;

  /// No description provided for @authLoginNow.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập ngay'**
  String get authLoginNow;

  /// No description provided for @authLogoutConfirmTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất'**
  String get authLogoutConfirmTitle;

  /// No description provided for @authLogoutConfirmMessage.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc chắn muốn đăng xuất không?'**
  String get authLogoutConfirmMessage;

  /// No description provided for @authEmailRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập email'**
  String get authEmailRequired;

  /// No description provided for @authPasswordRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập mật khẩu'**
  String get authPasswordRequired;

  /// No description provided for @authAccountAndPasswordRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập tài khoản và mật khẩu'**
  String get authAccountAndPasswordRequired;

  /// No description provided for @authPasswordMismatch.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu xác nhận không khớp'**
  String get authPasswordMismatch;

  /// No description provided for @authAgreeTerms.
  ///
  /// In vi, this message translates to:
  /// **'Tôi đồng ý với Điều khoản dịch vụ & Chính sách bảo mật'**
  String get authAgreeTerms;

  /// No description provided for @authNameRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập họ và tên'**
  String get authNameRequired;

  /// No description provided for @authEmailInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập email hợp lệ'**
  String get authEmailInvalid;

  /// No description provided for @authPhoneRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập số điện thoại'**
  String get authPhoneRequired;

  /// No description provided for @authAddressRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập địa chỉ'**
  String get authAddressRequired;

  /// No description provided for @authPasswordMinLength.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu phải có ít nhất 6 ký tự'**
  String get authPasswordMinLength;

  /// No description provided for @authAgreeTermsRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng đồng ý với điều khoản dịch vụ để tiếp tục'**
  String get authAgreeTermsRequired;

  /// No description provided for @authSignUpSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký thành công!'**
  String get authSignUpSuccess;

  /// No description provided for @authSignUpFailed.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký thất bại. Vui lòng thử lại!'**
  String get authSignUpFailed;

  /// No description provided for @homeDeliverTo.
  ///
  /// In vi, this message translates to:
  /// **'GIAO ĐẾN HIỆN TẠI'**
  String get homeDeliverTo;

  /// No description provided for @homePickupPoint.
  ///
  /// In vi, this message translates to:
  /// **'ĐIỂM ĐÓN'**
  String get homePickupPoint;

  /// No description provided for @homePickupHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập vị trí điểm đón...'**
  String get homePickupHint;

  /// No description provided for @homeDestination.
  ///
  /// In vi, this message translates to:
  /// **'ĐIỂM ĐẾN'**
  String get homeDestination;

  /// No description provided for @homeDestinationHint.
  ///
  /// In vi, this message translates to:
  /// **'Chọn địa điểm đến...'**
  String get homeDestinationHint;

  /// No description provided for @homeFoodSearchHint.
  ///
  /// In vi, this message translates to:
  /// **'Tìm món ăn, quán ngon tiện đường...'**
  String get homeFoodSearchHint;

  /// No description provided for @homeMyLocation.
  ///
  /// In vi, this message translates to:
  /// **'Vị trí của tôi'**
  String get homeMyLocation;

  /// No description provided for @homeClearRoute.
  ///
  /// In vi, this message translates to:
  /// **'Xóa đường đi'**
  String get homeClearRoute;

  /// No description provided for @homeNavigatingToStore.
  ///
  /// In vi, this message translates to:
  /// **'Đang dẫn đường ghé: {storeName}'**
  String homeNavigatingToStore(String storeName);

  /// No description provided for @homeNavigatingWithOrder.
  ///
  /// In vi, this message translates to:
  /// **'Đang dẫn đường ghé: {storeName} (Đơn #{orderCode})'**
  String homeNavigatingWithOrder(String storeName, String orderCode);

  /// No description provided for @homePickedUpContinue.
  ///
  /// In vi, this message translates to:
  /// **'Đã lấy món tại {storeName} • Tiếp tục đến {destName}'**
  String homePickedUpContinue(String storeName, String destName);

  /// No description provided for @homeCategories.
  ///
  /// In vi, this message translates to:
  /// **'Danh mục'**
  String get homeCategories;

  /// No description provided for @homePopularRestaurants.
  ///
  /// In vi, this message translates to:
  /// **'Quán ngon phổ biến'**
  String get homePopularRestaurants;

  /// No description provided for @homeNearbyRestaurants.
  ///
  /// In vi, this message translates to:
  /// **'Quán ngon gần bạn'**
  String get homeNearbyRestaurants;

  /// No description provided for @homeSuggestedStops.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý điểm dừng tiện đường'**
  String get homeSuggestedStops;

  /// No description provided for @homeFoodSearchAlongRoute.
  ///
  /// In vi, this message translates to:
  /// **'TÌM MÓN DỌC TUYẾN ĐƯỜNG'**
  String get homeFoodSearchAlongRoute;

  /// No description provided for @homeSubtextTravel.
  ///
  /// In vi, this message translates to:
  /// **'{minutes}p di chuyển'**
  String homeSubtextTravel(int minutes);

  /// No description provided for @homeSubtextQuickPickup.
  ///
  /// In vi, this message translates to:
  /// **'Ghé lấy nhanh'**
  String get homeSubtextQuickPickup;

  /// No description provided for @homeSubtextPreOrderPrep.
  ///
  /// In vi, this message translates to:
  /// **'Chuẩn bị ~45p'**
  String get homeSubtextPreOrderPrep;

  /// No description provided for @homeSubtextDineInRelax.
  ///
  /// In vi, this message translates to:
  /// **'Thoải mái ghé'**
  String get homeSubtextDineInRelax;

  /// No description provided for @menuAddToCart.
  ///
  /// In vi, this message translates to:
  /// **'Thêm vào giỏ hàng'**
  String get menuAddToCart;

  /// No description provided for @menuItemDetails.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết món ăn'**
  String get menuItemDetails;

  /// No description provided for @menuRestaurantDetails.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin nhà hàng'**
  String get menuRestaurantDetails;

  /// No description provided for @menuSpecialInstructions.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú cho quán'**
  String get menuSpecialInstructions;

  /// No description provided for @menuSpecialInstructionsHint.
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ: ít đường, không cay, để riêng đá...'**
  String get menuSpecialInstructionsHint;

  /// No description provided for @menuSize.
  ///
  /// In vi, this message translates to:
  /// **'Kích thước / Size'**
  String get menuSize;

  /// No description provided for @menuToppings.
  ///
  /// In vi, this message translates to:
  /// **'Topping thêm'**
  String get menuToppings;

  /// No description provided for @menuReviews.
  ///
  /// In vi, this message translates to:
  /// **'Đánh giá món ăn'**
  String get menuReviews;

  /// No description provided for @menuAddedToCart.
  ///
  /// In vi, this message translates to:
  /// **'Đã thêm vào giỏ hàng thành công'**
  String get menuAddedToCart;

  /// No description provided for @cartTitle.
  ///
  /// In vi, this message translates to:
  /// **'Giỏ hàng & Đặt trước'**
  String get cartTitle;

  /// No description provided for @cartEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Giỏ hàng của bạn đang trống'**
  String get cartEmptyTitle;

  /// No description provided for @cartEmptySubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Khám phá thực đơn và thêm món ăn yêu thích của bạn'**
  String get cartEmptySubtitle;

  /// No description provided for @cartExploreNow.
  ///
  /// In vi, this message translates to:
  /// **'Khám phá ngay'**
  String get cartExploreNow;

  /// No description provided for @cartPickupTime.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian ghé lấy dự kiến'**
  String get cartPickupTime;

  /// No description provided for @cartPickupToday.
  ///
  /// In vi, this message translates to:
  /// **'Ghé lấy hôm nay'**
  String get cartPickupToday;

  /// No description provided for @cartPickupOtherDay.
  ///
  /// In vi, this message translates to:
  /// **'Hẹn ngày khác'**
  String get cartPickupOtherDay;

  /// No description provided for @cartSelectPickupTime.
  ///
  /// In vi, this message translates to:
  /// **'Chọn giờ ghé lấy'**
  String get cartSelectPickupTime;

  /// No description provided for @cartVoucher.
  ///
  /// In vi, this message translates to:
  /// **'Mã giảm giá / Voucher'**
  String get cartVoucher;

  /// No description provided for @cartSelectVoucher.
  ///
  /// In vi, this message translates to:
  /// **'Chọn hoặc nhập mã giảm giá'**
  String get cartSelectVoucher;

  /// No description provided for @cartSubtotal.
  ///
  /// In vi, this message translates to:
  /// **'Tạm tính'**
  String get cartSubtotal;

  /// No description provided for @cartDiscount.
  ///
  /// In vi, this message translates to:
  /// **'Giảm giá voucher'**
  String get cartDiscount;

  /// No description provided for @cartTotal.
  ///
  /// In vi, this message translates to:
  /// **'Tổng thanh toán'**
  String get cartTotal;

  /// No description provided for @cartProceedCheckout.
  ///
  /// In vi, this message translates to:
  /// **'Tiến hành thanh toán'**
  String get cartProceedCheckout;

  /// No description provided for @checkoutTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận đơn hàng'**
  String get checkoutTitle;

  /// No description provided for @checkoutPickupTime.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian ghé lấy'**
  String get checkoutPickupTime;

  /// No description provided for @checkoutPaymentMethod.
  ///
  /// In vi, this message translates to:
  /// **'Phương thức thanh toán'**
  String get checkoutPaymentMethod;

  /// No description provided for @checkoutSelectedItems.
  ///
  /// In vi, this message translates to:
  /// **'Món đã chọn'**
  String get checkoutSelectedItems;

  /// No description provided for @checkoutOrderNotes.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú đơn hàng'**
  String get checkoutOrderNotes;

  /// No description provided for @checkoutPlaceOrder.
  ///
  /// In vi, this message translates to:
  /// **'Đặt đơn ngay'**
  String get checkoutPlaceOrder;

  /// No description provided for @checkoutSuccessTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đặt món thành công!'**
  String get checkoutSuccessTitle;

  /// No description provided for @checkoutSuccessSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Đơn hàng của bạn đã được gửi tới quán. Quán sẽ chuẩn bị đúng giờ bạn ghé lấy.'**
  String get checkoutSuccessSubtitle;

  /// No description provided for @checkoutViewOrder.
  ///
  /// In vi, this message translates to:
  /// **'Xem đơn hàng'**
  String get checkoutViewOrder;

  /// No description provided for @orderHistoryTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đơn hàng của tôi'**
  String get orderHistoryTitle;

  /// No description provided for @orderHistoryTabActive.
  ///
  /// In vi, this message translates to:
  /// **'Đang đến'**
  String get orderHistoryTabActive;

  /// No description provided for @orderHistoryTabCompleted.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử'**
  String get orderHistoryTabCompleted;

  /// No description provided for @orderHistoryEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có đơn hàng nào'**
  String get orderHistoryEmpty;

  /// No description provided for @orderDetailTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết đơn hàng'**
  String get orderDetailTitle;

  /// No description provided for @orderCode.
  ///
  /// In vi, this message translates to:
  /// **'Mã đơn hàng'**
  String get orderCode;

  /// No description provided for @orderPickupEstimate.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian ghé lấy dự kiến'**
  String get orderPickupEstimate;

  /// No description provided for @orderCancelReason.
  ///
  /// In vi, this message translates to:
  /// **'Lý do hủy:'**
  String get orderCancelReason;

  /// No description provided for @orderReviewButton.
  ///
  /// In vi, this message translates to:
  /// **'Đánh giá'**
  String get orderReviewButton;

  /// No description provided for @orderReorderButton.
  ///
  /// In vi, this message translates to:
  /// **'Đặt lại'**
  String get orderReorderButton;

  /// No description provided for @orderCancelButton.
  ///
  /// In vi, this message translates to:
  /// **'Hủy đơn'**
  String get orderCancelButton;

  /// No description provided for @orderStepperStep1.
  ///
  /// In vi, this message translates to:
  /// **'Chờ xác nhận'**
  String get orderStepperStep1;

  /// No description provided for @orderStepperStep2.
  ///
  /// In vi, this message translates to:
  /// **'Đã xác nhận'**
  String get orderStepperStep2;

  /// No description provided for @orderStepperStep3.
  ///
  /// In vi, this message translates to:
  /// **'Đang chuẩn bị'**
  String get orderStepperStep3;

  /// No description provided for @orderStepperStep4.
  ///
  /// In vi, this message translates to:
  /// **'Sẵn sàng ghé lấy'**
  String get orderStepperStep4;

  /// No description provided for @orderStepperStep5.
  ///
  /// In vi, this message translates to:
  /// **'Đã hoàn thành'**
  String get orderStepperStep5;

  /// No description provided for @orderStepperUnpaidBanner.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thanh toán (Chờ thanh toán VietQR)'**
  String get orderStepperUnpaidBanner;

  /// No description provided for @orderStepperUnpaidNote.
  ///
  /// In vi, this message translates to:
  /// **'Quán chưa tiếp nhận đơn cho đến khi bạn hoàn tất thanh toán.'**
  String get orderStepperUnpaidNote;

  /// No description provided for @orderStepperCancelledBanner.
  ///
  /// In vi, this message translates to:
  /// **'Đơn hàng đã bị hủy'**
  String get orderStepperCancelledBanner;

  /// No description provided for @settingsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ'**
  String get settingsLanguage;

  /// No description provided for @settingsThemeMode.
  ///
  /// In vi, this message translates to:
  /// **'Giao diện'**
  String get settingsThemeMode;

  /// No description provided for @settingsSelectLanguage.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ngôn ngữ'**
  String get settingsSelectLanguage;

  /// No description provided for @settingsSelectTheme.
  ///
  /// In vi, this message translates to:
  /// **'Chọn chế độ giao diện'**
  String get settingsSelectTheme;

  /// No description provided for @settingsVietnamese.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Việt'**
  String get settingsVietnamese;

  /// No description provided for @settingsEnglish.
  ///
  /// In vi, this message translates to:
  /// **'English'**
  String get settingsEnglish;

  /// No description provided for @settingsLightMode.
  ///
  /// In vi, this message translates to:
  /// **'Chế độ Sáng'**
  String get settingsLightMode;

  /// No description provided for @settingsDarkMode.
  ///
  /// In vi, this message translates to:
  /// **'Chế độ Tối'**
  String get settingsDarkMode;

  /// No description provided for @settingsSystemMode.
  ///
  /// In vi, this message translates to:
  /// **'Theo hệ thống'**
  String get settingsSystemMode;

  /// No description provided for @moreTitle.
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get moreTitle;

  /// No description provided for @moreLanguageSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ hiển thị'**
  String get moreLanguageSubtitle;

  /// No description provided for @morePaymentDetails.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết thanh toán'**
  String get morePaymentDetails;

  /// No description provided for @morePaymentDetailsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Thẻ & ví điện tử'**
  String get morePaymentDetailsSubtitle;

  /// No description provided for @moreMyOrder.
  ///
  /// In vi, this message translates to:
  /// **'Đơn hàng của tôi'**
  String get moreMyOrder;

  /// No description provided for @moreMyOrderSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử và theo dõi đơn'**
  String get moreMyOrderSubtitle;

  /// No description provided for @moreReservations.
  ///
  /// In vi, this message translates to:
  /// **'Đặt bàn của tôi'**
  String get moreReservations;

  /// No description provided for @moreReservationsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý lịch hẹn & bàn ăn tại quán'**
  String get moreReservationsSubtitle;

  /// No description provided for @moreNotifications.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo'**
  String get moreNotifications;

  /// No description provided for @moreNotificationsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Ưu đãi & tin tức quan trọng'**
  String get moreNotificationsSubtitle;

  /// No description provided for @moreInbox.
  ///
  /// In vi, this message translates to:
  /// **'Voucher cho tôi'**
  String get moreInbox;

  /// No description provided for @moreInboxSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Kho voucher & mã giảm giá'**
  String get moreInboxSubtitle;

  /// No description provided for @moreBecomeStore.
  ///
  /// In vi, this message translates to:
  /// **'Trở thành cửa hàng'**
  String get moreBecomeStore;

  /// No description provided for @moreBecomeStoreSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký bán hàng cùng Food Route'**
  String get moreBecomeStoreSubtitle;

  /// No description provided for @morePartnerInfoSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý & thông tin đối tác'**
  String get morePartnerInfoSubtitle;

  /// No description provided for @moreRestaurantPortal.
  ///
  /// In vi, this message translates to:
  /// **'Giao diện Cửa Hàng'**
  String get moreRestaurantPortal;

  /// No description provided for @moreRestaurantPortalSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý đơn hàng, thực đơn & doanh thu'**
  String get moreRestaurantPortalSubtitle;

  /// No description provided for @moreSupportCenter.
  ///
  /// In vi, this message translates to:
  /// **'Trung tâm hỗ trợ'**
  String get moreSupportCenter;

  /// No description provided for @moreSupportCenterSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Hotline, FAQ & Góp ý phản hồi'**
  String get moreSupportCenterSubtitle;

  /// No description provided for @moreAboutUs.
  ///
  /// In vi, this message translates to:
  /// **'Về chúng tôi'**
  String get moreAboutUs;

  /// No description provided for @moreAboutUsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Phiên bản v2.4.0 • Điều khoản'**
  String get moreAboutUsSubtitle;

  /// No description provided for @moreLogout.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất'**
  String get moreLogout;

  /// No description provided for @moreLogoutSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Thoát tài khoản hiện tại'**
  String get moreLogoutSubtitle;

  /// No description provided for @moreSelectLanguageSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Lựa chọn ngôn ngữ hiển thị chính'**
  String get moreSelectLanguageSubtitle;

  /// No description provided for @moreSelectThemeSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Lựa chọn chế độ giao diện cho ứng dụng'**
  String get moreSelectThemeSubtitle;

  /// No description provided for @moreLangViSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Mặc định hệ thống'**
  String get moreLangViSubtitle;

  /// No description provided for @moreLangEnSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ quốc tế'**
  String get moreLangEnSubtitle;

  /// No description provided for @moreThemeLightSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Giao diện sáng rực rỡ'**
  String get moreThemeLightSubtitle;

  /// No description provided for @moreThemeDarkSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tối màu dịu mắt, tiết kiệm pin'**
  String get moreThemeDarkSubtitle;

  /// No description provided for @moreThemeSystemSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tự động đồng bộ cài đặt máy'**
  String get moreThemeSystemSubtitle;

  /// No description provided for @storeRejectedReason.
  ///
  /// In vi, this message translates to:
  /// **'Đơn đăng ký cửa hàng bị từ chối: {reason}'**
  String storeRejectedReason(String reason);

  /// No description provided for @storeRejectedDefault.
  ///
  /// In vi, this message translates to:
  /// **'Đơn đăng ký cửa hàng của bạn chưa được phê duyệt.'**
  String get storeRejectedDefault;

  /// No description provided for @menuConvenientPickup.
  ///
  /// In vi, this message translates to:
  /// **'TIỆN ĐƯỜNG GHÉ LẤY'**
  String get menuConvenientPickup;

  /// No description provided for @menuLocating.
  ///
  /// In vi, this message translates to:
  /// **'Đang xác định vị trí...'**
  String get menuLocating;

  /// No description provided for @menuSearchFoodHint.
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm phở bò, cơm tấm, trà sữa...'**
  String get menuSearchFoodHint;

  /// No description provided for @menuFeaturedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thực Đơn Quán Tuyển Chọn'**
  String get menuFeaturedTitle;

  /// No description provided for @menuGroupCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} Nhóm món'**
  String menuGroupCount(int count);

  /// No description provided for @menuReadyPickupSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Đóng gói sẵn sàng, dừng xe lấy trong 1 phút'**
  String get menuReadyPickupSubtitle;

  /// No description provided for @menuFreshCookedSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Chế biến tươi nóng • Gia vị gia truyền 24h'**
  String get menuFreshCookedSubtitle;

  /// No description provided for @menuServingItemCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} món đang phục vụ'**
  String menuServingItemCount(int count);

  /// No description provided for @menuNoCategories.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có danh mục nào trong cơ sở dữ liệu'**
  String get menuNoCategories;

  /// No description provided for @menuReloadButton.
  ///
  /// In vi, this message translates to:
  /// **'Tải lại thực đơn'**
  String get menuReloadButton;

  /// No description provided for @menuRoutePickupTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tiện Đường Ghé Lấy'**
  String get menuRoutePickupTitle;

  /// No description provided for @menuViewMap.
  ///
  /// In vi, this message translates to:
  /// **'Bản đồ'**
  String get menuViewMap;

  /// No description provided for @menuDistanceForm.
  ///
  /// In vi, this message translates to:
  /// **'Cách bạn từ {dist} • Chuẩn bị nhanh từ {min}p'**
  String menuDistanceForm(String dist, int min);

  /// No description provided for @storeRouteHeader.
  ///
  /// In vi, this message translates to:
  /// **'CỬA HÀNG LỘ TRÌNH'**
  String get storeRouteHeader;

  /// No description provided for @storeNearbyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cửa hàng gần bạn'**
  String get storeNearbyTitle;

  /// No description provided for @storeNoFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy cửa hàng nào thuộc danh mục này'**
  String get storeNoFound;

  /// No description provided for @storeReloadButton.
  ///
  /// In vi, this message translates to:
  /// **'Tải lại danh sách quán'**
  String get storeReloadButton;

  /// No description provided for @storeFilterAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get storeFilterAll;

  /// No description provided for @cartPickupNote.
  ///
  /// In vi, this message translates to:
  /// **'Món ăn sẽ được nhà hàng chuẩn bị sẵn sàng vào thời điểm trên.'**
  String get cartPickupNote;

  /// No description provided for @cartShippingFee.
  ///
  /// In vi, this message translates to:
  /// **'Phí giao hàng'**
  String get cartShippingFee;

  /// No description provided for @cartShippingFree.
  ///
  /// In vi, this message translates to:
  /// **'0đ (Tự đến lấy)'**
  String get cartShippingFree;

  /// No description provided for @cartPickupTimeInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian hẹn lấy phải cách hiện tại ít nhất 5 phút!'**
  String get cartPickupTimeInvalid;

  /// No description provided for @cartProceedConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận đặt món & Thanh toán'**
  String get cartProceedConfirm;

  /// No description provided for @voucherTabAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get voucherTabAll;

  /// No description provided for @voucherTabDiscount.
  ///
  /// In vi, this message translates to:
  /// **'Mã giảm giá'**
  String get voucherTabDiscount;

  /// No description provided for @voucherTabSaved.
  ///
  /// In vi, this message translates to:
  /// **'Voucher đã lưu'**
  String get voucherTabSaved;

  /// No description provided for @voucherEmptyWallet.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có voucher nào trong ví'**
  String get voucherEmptyWallet;

  /// No description provided for @voucherEmptyWalletSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Hãy bấm \'Thu thập\' để lưu mã giảm giá vào ví'**
  String get voucherEmptyWalletSubtitle;

  /// No description provided for @voucherEmptyAvailable.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có voucher khả dụng nào'**
  String get voucherEmptyAvailable;

  /// No description provided for @voucherEmptyAvailableSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả voucher có thể đã được thu thập hoặc hết hạn'**
  String get voucherEmptyAvailableSubtitle;

  /// No description provided for @voucherCodeLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mã'**
  String get voucherCodeLabel;

  /// No description provided for @voucherExpiryLabel.
  ///
  /// In vi, this message translates to:
  /// **'Hạn dùng'**
  String get voucherExpiryLabel;

  /// No description provided for @voucherStatusSaved.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu'**
  String get voucherStatusSaved;

  /// No description provided for @voucherActionCollect.
  ///
  /// In vi, this message translates to:
  /// **'Thu thập'**
  String get voucherActionCollect;

  /// No description provided for @voucherCollectedSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu mã {code} vào ví của bạn!'**
  String voucherCollectedSuccess(String code);

  /// No description provided for @voucherCollectFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể lưu voucher'**
  String get voucherCollectFailed;

  /// No description provided for @voucherSelectTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chọn Ưu Đãi Khuyến Mãi'**
  String get voucherSelectTitle;

  /// No description provided for @voucherInputHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã giảm giá...'**
  String get voucherInputHint;

  /// No description provided for @voucherInputRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập mã voucher'**
  String get voucherInputRequired;

  /// No description provided for @voucherInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Mã voucher không hợp lệ'**
  String get voucherInvalid;

  /// No description provided for @singleStoreWarningTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ đặt 1 quán mỗi lần'**
  String get singleStoreWarningTitle;

  /// No description provided for @singleStoreWarningPart1.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đang có món từ '**
  String get singleStoreWarningPart1;

  /// No description provided for @singleStoreWarningPart2.
  ///
  /// In vi, this message translates to:
  /// **' trong giỏ hàng.\n\nVui lòng thanh toán xong rồi mới đặt ở '**
  String get singleStoreWarningPart2;

  /// No description provided for @singleStoreWarningCartBadge.
  ///
  /// In vi, this message translates to:
  /// **'Giỏ hiện có {count} món ({price})'**
  String singleStoreWarningCartBadge(int count, String price);

  /// No description provided for @singleStoreWarningPayExisting.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán giỏ hiện tại trước'**
  String get singleStoreWarningPayExisting;

  /// No description provided for @singleStoreWarningClearAndOrder.
  ///
  /// In vi, this message translates to:
  /// **'Xóa giỏ hàng & đặt quán mới'**
  String get singleStoreWarningClearAndOrder;

  /// No description provided for @orderCancelledTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đơn hàng đã được hủy'**
  String get orderCancelledTitle;

  /// No description provided for @orderCancelledDefaultMsg.
  ///
  /// In vi, this message translates to:
  /// **'Đơn hàng chưa thanh toán đã được hủy thành công.\nKhông phát sinh giao dịch hoàn tiền.'**
  String get orderCancelledDefaultMsg;

  /// No description provided for @orderCancelledBackHome.
  ///
  /// In vi, this message translates to:
  /// **'Về trang chủ'**
  String get orderCancelledBackHome;

  /// No description provided for @orderCancelledViewOrder.
  ///
  /// In vi, this message translates to:
  /// **'Xem đơn hàng'**
  String get orderCancelledViewOrder;

  /// No description provided for @orderEnjoyMealTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chúc Quý Khách Ngon Miệng!'**
  String get orderEnjoyMealTitle;

  /// No description provided for @orderEnjoyMealSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Đã lấy món thành công. Chúc bạn có một hành trình thật an toàn và thuận lợi!'**
  String get orderEnjoyMealSubtitle;

  /// No description provided for @orderEnjoyMealContinue.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tất & Tiếp tục lộ trình'**
  String get orderEnjoyMealContinue;

  /// No description provided for @orderEnjoyMealReviewMap.
  ///
  /// In vi, this message translates to:
  /// **'Xem lại bản đồ (nếu bấm nhầm)'**
  String get orderEnjoyMealReviewMap;

  /// No description provided for @modalFeedbackThanksTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cảm ơn bạn!'**
  String get modalFeedbackThanksTitle;

  /// No description provided for @modalFeedbackThanksMessage.
  ///
  /// In vi, this message translates to:
  /// **'Góp ý của bạn đã được ghi nhận. Đội ngũ Food Route sẽ luôn nỗ lực cải thiện để mang đến dịch vụ tốt nhất!'**
  String get modalFeedbackThanksMessage;

  /// No description provided for @modalFeedbackBadge.
  ///
  /// In vi, this message translates to:
  /// **'ĐÃ GHI NHẬN GÓP Ý'**
  String get modalFeedbackBadge;

  /// No description provided for @profilePaymentDetails.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết thanh toán'**
  String get profilePaymentDetails;

  /// No description provided for @profileAboutUs.
  ///
  /// In vi, this message translates to:
  /// **'Về chúng tôi'**
  String get profileAboutUs;

  /// No description provided for @profileChangeAddress.
  ///
  /// In vi, this message translates to:
  /// **'Đổi địa chỉ'**
  String get profileChangeAddress;

  /// No description provided for @formatItemCount.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} món}}'**
  String formatItemCount(int count);

  /// No description provided for @formatMinuteCount.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} phút}}'**
  String formatMinuteCount(int count);

  /// No description provided for @formatTableCount.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} bàn}}'**
  String formatTableCount(int count);

  /// No description provided for @formatJustNow.
  ///
  /// In vi, this message translates to:
  /// **'Vừa xong'**
  String get formatJustNow;

  /// No description provided for @formatMinutesAgo.
  ///
  /// In vi, this message translates to:
  /// **'{count} phút trước'**
  String formatMinutesAgo(int count);

  /// No description provided for @formatHoursAgo.
  ///
  /// In vi, this message translates to:
  /// **'{count} giờ trước'**
  String formatHoursAgo(int count);

  /// No description provided for @formatDaysAgo.
  ///
  /// In vi, this message translates to:
  /// **'{count} ngày trước'**
  String formatDaysAgo(int count);

  /// No description provided for @cartSelectOrInputVoucher.
  ///
  /// In vi, this message translates to:
  /// **'Chọn hoặc nhập mã Voucher'**
  String get cartSelectOrInputVoucher;

  /// No description provided for @cartVoucherDirectDiscount.
  ///
  /// In vi, this message translates to:
  /// **'Giảm tiền trực tiếp cho đơn pre-order'**
  String get cartVoucherDirectDiscount;

  /// No description provided for @cartVoucherAppliedDiscount.
  ///
  /// In vi, this message translates to:
  /// **'Đã giảm -{amount}'**
  String cartVoucherAppliedDiscount(String amount);

  /// No description provided for @storeStatusOpen.
  ///
  /// In vi, this message translates to:
  /// **'Đang mở'**
  String get storeStatusOpen;

  /// No description provided for @storeStatusClosed.
  ///
  /// In vi, this message translates to:
  /// **'Đóng cửa'**
  String get storeStatusClosed;

  /// No description provided for @storeDineInReservation.
  ///
  /// In vi, this message translates to:
  /// **'Đặt bàn tại quán (Dine-in)'**
  String get storeDineInReservation;

  /// No description provided for @storeTabAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get storeTabAll;

  /// No description provided for @storeTabMenu.
  ///
  /// In vi, this message translates to:
  /// **'Thực đơn'**
  String get storeTabMenu;

  /// No description provided for @storeEmptyItems.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có món ăn nào trong nhà hàng này'**
  String get storeEmptyItems;

  /// No description provided for @storeFloatingCartTotal.
  ///
  /// In vi, this message translates to:
  /// **'Tổng thanh toán ({count} món)'**
  String storeFloatingCartTotal(int count);

  /// No description provided for @storeFloatingOrderNow.
  ///
  /// In vi, this message translates to:
  /// **'Đặt hàng ngay'**
  String get storeFloatingOrderNow;

  /// No description provided for @quickCatDiscount50.
  ///
  /// In vi, this message translates to:
  /// **'Món Giảm 50%'**
  String get quickCatDiscount50;

  /// No description provided for @quickCatBobaCoffee.
  ///
  /// In vi, this message translates to:
  /// **'Trà Sữa / Cà Phê'**
  String get quickCatBobaCoffee;

  /// No description provided for @quickCatHotNoodles.
  ///
  /// In vi, this message translates to:
  /// **'Phở & Bún Nóng'**
  String get quickCatHotNoodles;

  /// No description provided for @quickCatHotLunch.
  ///
  /// In vi, this message translates to:
  /// **'Cơm Trưa Nóng'**
  String get quickCatHotLunch;

  /// No description provided for @quickCatBanhMiFast.
  ///
  /// In vi, this message translates to:
  /// **'Bánh Mì & Nhanh'**
  String get quickCatBanhMiFast;

  /// No description provided for @quickCatSnacks.
  ///
  /// In vi, this message translates to:
  /// **'Ăn Kèm & Vặt'**
  String get quickCatSnacks;

  /// No description provided for @quickCatEatClean.
  ///
  /// In vi, this message translates to:
  /// **'Eat Clean Healthy'**
  String get quickCatEatClean;

  /// No description provided for @quickCatPickup0d.
  ///
  /// In vi, this message translates to:
  /// **'Ghé Lấy 0Đ'**
  String get quickCatPickup0d;

  /// No description provided for @menuFilteringBy.
  ///
  /// In vi, this message translates to:
  /// **'Đang lọc: {category} ({count} món)'**
  String menuFilteringBy(String category, int count);

  /// No description provided for @menuSearchResultsCount.
  ///
  /// In vi, this message translates to:
  /// **'Kết quả cho \'{query}\' ({count} món)'**
  String menuSearchResultsCount(String query, int count);

  /// No description provided for @menuClearFilter.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ lọc'**
  String get menuClearFilter;

  /// No description provided for @storeFilterPho.
  ///
  /// In vi, this message translates to:
  /// **'Phở'**
  String get storeFilterPho;

  /// No description provided for @storeFilterNoodles.
  ///
  /// In vi, this message translates to:
  /// **'Bún'**
  String get storeFilterNoodles;

  /// No description provided for @storeFilterRice.
  ///
  /// In vi, this message translates to:
  /// **'Cơm'**
  String get storeFilterRice;

  /// No description provided for @storeFilterCoffee.
  ///
  /// In vi, this message translates to:
  /// **'Cà phê'**
  String get storeFilterCoffee;

  /// No description provided for @storeFilterMilkTea.
  ///
  /// In vi, this message translates to:
  /// **'Trà sữa'**
  String get storeFilterMilkTea;

  /// No description provided for @storeFilterPastry.
  ///
  /// In vi, this message translates to:
  /// **'Bánh ngọt'**
  String get storeFilterPastry;

  /// No description provided for @storeFilterBanhMi.
  ///
  /// In vi, this message translates to:
  /// **'Bánh mì'**
  String get storeFilterBanhMi;

  /// No description provided for @storeFilterBirthdayCake.
  ///
  /// In vi, this message translates to:
  /// **'Bánh sinh nhật'**
  String get storeFilterBirthdayCake;

  /// No description provided for @storeFilterIceCream.
  ///
  /// In vi, this message translates to:
  /// **'Kem'**
  String get storeFilterIceCream;

  /// No description provided for @storeBadgeRouteDiscount10k.
  ///
  /// In vi, this message translates to:
  /// **'ƯU ĐÃI LỘ TRÌNH 10K'**
  String get storeBadgeRouteDiscount10k;

  /// No description provided for @storePrepTime15to20.
  ///
  /// In vi, this message translates to:
  /// **'15-20 phút'**
  String get storePrepTime15to20;

  /// No description provided for @storeFeaturedDishes.
  ///
  /// In vi, this message translates to:
  /// **'Món nổi bật:'**
  String get storeFeaturedDishes;

  /// No description provided for @storeGiftRoutePickup.
  ///
  /// In vi, this message translates to:
  /// **'Đặt trước ghé lấy tiện đường'**
  String get storeGiftRoutePickup;

  /// No description provided for @storeViewMenu.
  ///
  /// In vi, this message translates to:
  /// **'Xem menu'**
  String get storeViewMenu;

  /// No description provided for @storeCuisineVietnamese.
  ///
  /// In vi, this message translates to:
  /// **'Món Việt'**
  String get storeCuisineVietnamese;

  /// No description provided for @storeRouteSpecialty.
  ///
  /// In vi, this message translates to:
  /// **'Đặc sản lộ trình'**
  String get storeRouteSpecialty;

  /// No description provided for @storeRatingsCount.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{({count} đánh giá)}}'**
  String storeRatingsCount(int count);

  /// No description provided for @paymentOptionsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tùy chọn thanh toán'**
  String get paymentOptionsTitle;

  /// No description provided for @paymentOptionsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ví điện tử hoặc cổng thanh toán trực tuyến bạn muốn sử dụng làm mặc định khi đặt món.'**
  String get paymentOptionsSubtitle;

  /// No description provided for @paymentCashlessBannerTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán trực tuyến (Cashless)'**
  String get paymentCashlessBannerTitle;

  /// No description provided for @paymentCashlessBannerSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả đơn hàng Pre-Order được thanh toán và xác nhận tự động qua ví điện tử.'**
  String get paymentCashlessBannerSubtitle;

  /// No description provided for @paymentGatewaysSectionTitle.
  ///
  /// In vi, this message translates to:
  /// **'VÍ ĐIỆN TỬ & CỔNG THANH TOÁN'**
  String get paymentGatewaysSectionTitle;

  /// No description provided for @paymentGatewaysAvailable.
  ///
  /// In vi, this message translates to:
  /// **'{count} CỔNG KHẢ DỤNG'**
  String paymentGatewaysAvailable(int count);

  /// No description provided for @paymentPciSecurityFootnote.
  ///
  /// In vi, this message translates to:
  /// **'Bảo mật PCI-DSS cấp độ 1 & Mã hóa SSL 256-bit'**
  String get paymentPciSecurityFootnote;

  /// No description provided for @paymentReconciliationFootnote.
  ///
  /// In vi, this message translates to:
  /// **'Giao dịch được đối soát và xác thực tự động trực tiếp qua cổng thanh toán'**
  String get paymentReconciliationFootnote;

  /// No description provided for @paymentHeaderSslSub.
  ///
  /// In vi, this message translates to:
  /// **'Bảo mật chuẩn mã hóa SSL 256-bit'**
  String get paymentHeaderSslSub;

  /// No description provided for @paymentDefaultToast.
  ///
  /// In vi, this message translates to:
  /// **'Đã chọn {name} làm ví thanh toán mặc định'**
  String paymentDefaultToast(String name);

  /// No description provided for @paymentTagRecommended.
  ///
  /// In vi, this message translates to:
  /// **'KHUYÊN DÙNG'**
  String get paymentTagRecommended;

  /// No description provided for @paymentTagPopular.
  ///
  /// In vi, this message translates to:
  /// **'PHỔ BIẾN'**
  String get paymentTagPopular;

  /// No description provided for @paymentTagConvenient.
  ///
  /// In vi, this message translates to:
  /// **'TIỆN LỢI'**
  String get paymentTagConvenient;

  /// No description provided for @paymentTagNationwide.
  ///
  /// In vi, this message translates to:
  /// **'TOÀN QUỐC'**
  String get paymentTagNationwide;

  /// No description provided for @paymentVietqrSub.
  ///
  /// In vi, this message translates to:
  /// **'Quét mã QR chuyển khoản ngân hàng 24/7 tự động xác nhận đơn trong 3 giây.'**
  String get paymentVietqrSub;

  /// No description provided for @paymentMomoSub.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán một chạm qua ví điện tử MoMo hoặc quét mã QR MoMo liên kết.'**
  String get paymentMomoSub;

  /// No description provided for @paymentZaloPaySub.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán an toàn, tức thì qua ứng dụng ví điện tử ZaloPay & Zalo.'**
  String get paymentZaloPaySub;

  /// No description provided for @paymentVnpaySub.
  ///
  /// In vi, this message translates to:
  /// **'Cổng thanh toán quốc gia, quét mã thanh toán trực tiếp từ mọi ứng dụng ngân hàng.'**
  String get paymentVnpaySub;

  /// No description provided for @addCardTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thêm thẻ tín dụng/ghi nợ'**
  String get addCardTitle;

  /// No description provided for @addCardNumberHint.
  ///
  /// In vi, this message translates to:
  /// **'Số thẻ'**
  String get addCardNumberHint;

  /// No description provided for @addCardExpiryLabel.
  ///
  /// In vi, this message translates to:
  /// **'Hạn dùng'**
  String get addCardExpiryLabel;

  /// No description provided for @addCardMonthHint.
  ///
  /// In vi, this message translates to:
  /// **'MM'**
  String get addCardMonthHint;

  /// No description provided for @addCardYearHint.
  ///
  /// In vi, this message translates to:
  /// **'YYYY'**
  String get addCardYearHint;

  /// No description provided for @addCardSecurityCodeHint.
  ///
  /// In vi, this message translates to:
  /// **'Mã bảo mật CVV/CVC'**
  String get addCardSecurityCodeHint;

  /// No description provided for @addCardFirstNameHint.
  ///
  /// In vi, this message translates to:
  /// **'Tên'**
  String get addCardFirstNameHint;

  /// No description provided for @addCardLastNameHint.
  ///
  /// In vi, this message translates to:
  /// **'Họ'**
  String get addCardLastNameHint;

  /// No description provided for @addCardRemoveAnytime.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có thể xóa thẻ này bất kỳ lúc nào'**
  String get addCardRemoveAnytime;

  /// No description provided for @addCardButton.
  ///
  /// In vi, this message translates to:
  /// **'Thêm thẻ'**
  String get addCardButton;

  /// No description provided for @orderConfirmCancelTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận hủy đơn hàng'**
  String get orderConfirmCancelTitle;

  /// No description provided for @orderConfirmCancelContent.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc chắn muốn hủy đơn hàng #{id} không? Thao tác này không thể hoàn tác.'**
  String orderConfirmCancelContent(String id);

  /// No description provided for @orderConfirmCancelPrompt.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc chắn muốn hủy đơn hàng #{id} tại {restaurant} không?'**
  String orderConfirmCancelPrompt(String id, String restaurant);

  /// No description provided for @orderConfirmCancelWarning.
  ///
  /// In vi, this message translates to:
  /// **'Thao tác hủy đơn không thể hoàn tác sau khi xác nhận.'**
  String get orderConfirmCancelWarning;

  /// No description provided for @orderKeepOrderBtn.
  ///
  /// In vi, this message translates to:
  /// **'Giữ lại đơn'**
  String get orderKeepOrderBtn;

  /// No description provided for @orderConfirmCancelAction.
  ///
  /// In vi, this message translates to:
  /// **'Hủy đơn hàng'**
  String get orderConfirmCancelAction;

  /// No description provided for @orderCancelSuccessMsg.
  ///
  /// In vi, this message translates to:
  /// **'Đã hủy đơn hàng #{id} thành công!'**
  String orderCancelSuccessMsg(String id);

  /// No description provided for @orderCancelFailedMsg.
  ///
  /// In vi, this message translates to:
  /// **'Không thể hủy đơn hàng #{id}. Vui lòng thử lại.'**
  String orderCancelFailedMsg(String id);

  /// No description provided for @orderCancelNotAllowed.
  ///
  /// In vi, this message translates to:
  /// **'Đơn hàng đang ở Bước {stepNum} (Bếp đang chuẩn bị). Không thể hủy đơn lúc này!'**
  String orderCancelNotAllowed(int stepNum);

  /// No description provided for @orderCancellingProgress.
  ///
  /// In vi, this message translates to:
  /// **'Đang xử lý hủy đơn...'**
  String get orderCancellingProgress;

  /// No description provided for @orderUnpaidSectionTitle.
  ///
  /// In vi, this message translates to:
  /// **'CHỜ THANH TOÁN ({count} ĐƠN)'**
  String orderUnpaidSectionTitle(int count);

  /// No description provided for @orderUnpaidSectionSub.
  ///
  /// In vi, this message translates to:
  /// **'Quán chưa nhận đơn'**
  String get orderUnpaidSectionSub;

  /// No description provided for @orderPreparingSectionTitle.
  ///
  /// In vi, this message translates to:
  /// **'ĐANG CHUẨN BỊ & GIAO ({count} ĐƠN)'**
  String orderPreparingSectionTitle(int count);

  /// No description provided for @orderPreparingSectionSub.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật tức thì'**
  String get orderPreparingSectionSub;

  /// No description provided for @orderCompletedSectionTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử đã lấy hàng'**
  String get orderCompletedSectionTitle;

  /// No description provided for @orderCancelledSectionTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đơn hàng đã hủy'**
  String get orderCancelledSectionTitle;

  /// No description provided for @orderContactRestaurant.
  ///
  /// In vi, this message translates to:
  /// **'Liên hệ nhà hàng'**
  String get orderContactRestaurant;

  /// No description provided for @orderCallNow.
  ///
  /// In vi, this message translates to:
  /// **'Gọi ngay'**
  String get orderCallNow;

  /// No description provided for @orderCallClose.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get orderCallClose;

  /// No description provided for @notifCravingSomething.
  ///
  /// In vi, this message translates to:
  /// **'Đang thèm gì đó?'**
  String get notifCravingSomething;

  /// No description provided for @notifDiscoverFoodNearYou.
  ///
  /// In vi, this message translates to:
  /// **'Khám phá món ngon gần bạn'**
  String get notifDiscoverFoodNearYou;

  /// No description provided for @notifOrderNow.
  ///
  /// In vi, this message translates to:
  /// **'Đặt món'**
  String get notifOrderNow;

  /// No description provided for @notifAllRead.
  ///
  /// In vi, this message translates to:
  /// **'Đã đọc tất cả'**
  String get notifAllRead;

  /// No description provided for @notifNewCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} thông báo mới'**
  String notifNewCount(int count);

  /// No description provided for @notifPeriodToday.
  ///
  /// In vi, this message translates to:
  /// **'HÔM NAY'**
  String get notifPeriodToday;

  /// No description provided for @notifPeriodEarlier.
  ///
  /// In vi, this message translates to:
  /// **'TRƯỚC ĐÓ'**
  String get notifPeriodEarlier;

  /// No description provided for @notifMarkAllRead.
  ///
  /// In vi, this message translates to:
  /// **'Đánh dấu đã đọc'**
  String get notifMarkAllRead;

  /// No description provided for @notifTabAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get notifTabAll;

  /// No description provided for @notifTabOrders.
  ///
  /// In vi, this message translates to:
  /// **'Đơn hàng'**
  String get notifTabOrders;

  /// No description provided for @notifTabPromos.
  ///
  /// In vi, this message translates to:
  /// **'Ưu đãi'**
  String get notifTabPromos;

  /// No description provided for @notifTabSystem.
  ///
  /// In vi, this message translates to:
  /// **'Hệ thống'**
  String get notifTabSystem;

  /// No description provided for @notifEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa có thông báo nào'**
  String get notifEmpty;

  /// No description provided for @notifSecurityEncrypted.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả thông báo đều được mã hóa an toàn'**
  String get notifSecurityEncrypted;

  /// No description provided for @voucherRemaining.
  ///
  /// In vi, this message translates to:
  /// **'Còn lại: {qty}/{total}'**
  String voucherRemaining(int qty, int total);

  /// No description provided for @voucherRewardsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Food Route Rewards & Deals ({count} khả dụng)'**
  String voucherRewardsSubtitle(int count);

  /// No description provided for @voucherUseNow.
  ///
  /// In vi, this message translates to:
  /// **'DÙNG NGAY'**
  String get voucherUseNow;

  /// No description provided for @supportHeroTitle.
  ///
  /// In vi, this message translates to:
  /// **'Trung Tâm Trợ Giúp'**
  String get supportHeroTitle;

  /// No description provided for @supportHeroDesc.
  ///
  /// In vi, this message translates to:
  /// **'Food Route luôn sẵn sàng đồng hành và giải đáp mọi thắc mắc của bạn.'**
  String get supportHeroDesc;

  /// No description provided for @supportSecIncidentChat.
  ///
  /// In vi, this message translates to:
  /// **'Báo Cáo Sự Cố & Chat Trực Tuyến'**
  String get supportSecIncidentChat;

  /// No description provided for @supportSecIncidentChatSub.
  ///
  /// In vi, this message translates to:
  /// **'Hội thoại trực tiếp với đội ngũ Admin hỗ trợ'**
  String get supportSecIncidentChatSub;

  /// No description provided for @supportSecDirectContact.
  ///
  /// In vi, this message translates to:
  /// **'Liên Hệ Trực Tiếp'**
  String get supportSecDirectContact;

  /// No description provided for @supportSecDirectContactSub.
  ///
  /// In vi, this message translates to:
  /// **'Đội ngũ chăm sóc khách hàng phục vụ tận tâm'**
  String get supportSecDirectContactSub;

  /// No description provided for @supportSecFaqFeedback.
  ///
  /// In vi, this message translates to:
  /// **'Hỏi Đáp & Trợ Giúp Nhanh'**
  String get supportSecFaqFeedback;

  /// No description provided for @supportSecFaqFeedbackSub.
  ///
  /// In vi, this message translates to:
  /// **'Tìm câu trả lời hoặc gửi phản hồi ý kiến'**
  String get supportSecFaqFeedbackSub;

  /// No description provided for @supportViewTickets.
  ///
  /// In vi, this message translates to:
  /// **'Danh Sách Yêu Cầu Hỗ Trợ'**
  String get supportViewTickets;

  /// No description provided for @supportCreateTicket.
  ///
  /// In vi, this message translates to:
  /// **'Tạo Yêu Cầu Hỗ Trợ Mới'**
  String get supportCreateTicket;

  /// No description provided for @supportCustomerHotline.
  ///
  /// In vi, this message translates to:
  /// **'Hotline Chăm Sóc Khách Hàng'**
  String get supportCustomerHotline;

  /// No description provided for @supportOnlineEmail.
  ///
  /// In vi, this message translates to:
  /// **'Email Hỗ Trực Tuyến'**
  String get supportOnlineEmail;

  /// No description provided for @supportFaqTitle.
  ///
  /// In vi, this message translates to:
  /// **'Câu Hỏi Thường Gặp (FAQ)'**
  String get supportFaqTitle;

  /// No description provided for @supportFeedbackTitle.
  ///
  /// In vi, this message translates to:
  /// **'Gửi Ý Kiến Đóng Góp'**
  String get supportFeedbackTitle;

  /// No description provided for @supportDialError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể mở trình quay số. Đã chép số hotline {phone} vào bộ nhớ tạm.'**
  String supportDialError(String phone);

  /// No description provided for @supportCopyEmailSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép địa chỉ email hỗ trợ ({email}) vào bộ nhớ tạm.'**
  String supportCopyEmailSuccess(String email);

  /// No description provided for @supportFeedbackTopic.
  ///
  /// In vi, this message translates to:
  /// **'Chủ đề góp ý'**
  String get supportFeedbackTopic;

  /// No description provided for @supportFeedbackInputTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tiêu đề'**
  String get supportFeedbackInputTitle;

  /// No description provided for @supportFeedbackDetail.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung chi tiết'**
  String get supportFeedbackDetail;

  /// No description provided for @supportFeedbackAttachImages.
  ///
  /// In vi, this message translates to:
  /// **'Đính kèm hình ảnh'**
  String get supportFeedbackAttachImages;

  /// No description provided for @supportFeedbackSubmit.
  ///
  /// In vi, this message translates to:
  /// **'Gửi ý kiến'**
  String get supportFeedbackSubmit;

  /// No description provided for @supportFeedbackThanksTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cảm ơn bạn!'**
  String get supportFeedbackThanksTitle;

  /// No description provided for @supportFeedbackMaxImages.
  ///
  /// In vi, this message translates to:
  /// **'Tối đa đính kèm 3 hình ảnh.'**
  String get supportFeedbackMaxImages;

  /// No description provided for @supportFeedbackUploadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Tải ảnh lên thất bại. Vui lòng thử lại!'**
  String get supportFeedbackUploadFailed;

  /// No description provided for @supportFeedbackFailedMsg.
  ///
  /// In vi, this message translates to:
  /// **'Gửi góp ý thất bại'**
  String get supportFeedbackFailedMsg;

  /// No description provided for @supportFaqSearchHint.
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm câu hỏi...'**
  String get supportFaqSearchHint;

  /// No description provided for @supportFaqEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy câu hỏi phù hợp'**
  String get supportFaqEmpty;

  /// No description provided for @aboutCoreValues.
  ///
  /// In vi, this message translates to:
  /// **'Giá trị cốt lõi'**
  String get aboutCoreValues;

  /// No description provided for @aboutStandard5Star.
  ///
  /// In vi, this message translates to:
  /// **'Tiêu chuẩn 5 sao'**
  String get aboutStandard5Star;

  /// No description provided for @aboutStoreCommitment.
  ///
  /// In vi, this message translates to:
  /// **'Cam kết của quán'**
  String get aboutStoreCommitment;

  /// No description provided for @aboutVersionPrefix.
  ///
  /// In vi, this message translates to:
  /// **'Phiên bản {version} • FoodRoute Official'**
  String aboutVersionPrefix(String version);

  /// No description provided for @aboutCopyrightDefault.
  ///
  /// In vi, this message translates to:
  /// **'© 2026 FoodRoute Inc. Giữ toàn bộ bản quyền hệ thống.'**
  String get aboutCopyrightDefault;

  /// No description provided for @storeStatusTitle.
  ///
  /// In vi, this message translates to:
  /// **'Trạng thái đăng ký đối tác'**
  String get storeStatusTitle;

  /// No description provided for @storeStatusReviewing.
  ///
  /// In vi, this message translates to:
  /// **'Đang duyệt hồ sơ'**
  String get storeStatusReviewing;

  /// No description provided for @storeStatusApproved.
  ///
  /// In vi, this message translates to:
  /// **'Đã phê duyệt'**
  String get storeStatusApproved;

  /// No description provided for @storeStatusRejected.
  ///
  /// In vi, this message translates to:
  /// **'Chưa được duyệt'**
  String get storeStatusRejected;

  /// No description provided for @storeStatusActionManage.
  ///
  /// In vi, this message translates to:
  /// **'Vào giao diện quản lý quán'**
  String get storeStatusActionManage;

  /// No description provided for @storeStatusActionReapply.
  ///
  /// In vi, this message translates to:
  /// **'Nộp lại hồ sơ đăng ký'**
  String get storeStatusActionReapply;

  /// No description provided for @supportMyTicketsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Phiếu Hỗ Trợ Của Bạn'**
  String get supportMyTicketsTitle;

  /// No description provided for @supportNewReportBtn.
  ///
  /// In vi, this message translates to:
  /// **'Báo Cáo Mới'**
  String get supportNewReportBtn;

  /// No description provided for @supportStatusNew.
  ///
  /// In vi, this message translates to:
  /// **'Mới'**
  String get supportStatusNew;

  /// No description provided for @supportStatusProcessing.
  ///
  /// In vi, this message translates to:
  /// **'Đang xử lý'**
  String get supportStatusProcessing;

  /// No description provided for @supportStatusResolved.
  ///
  /// In vi, this message translates to:
  /// **'Đã giải quyết'**
  String get supportStatusResolved;

  /// No description provided for @supportStatusClosed.
  ///
  /// In vi, this message translates to:
  /// **'Đã đóng'**
  String get supportStatusClosed;

  /// No description provided for @supportNoTicketsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có phiếu hỗ trợ nào'**
  String get supportNoTicketsTitle;

  /// No description provided for @supportNoTicketsDesc.
  ///
  /// In vi, this message translates to:
  /// **'Nếu gặp sự cố về đơn hàng hoặc ứng dụng, hãy bấm nút \"Báo Cáo Mới\" bên dưới để được hỗ trợ trực tiếp.'**
  String get supportNoTicketsDesc;

  /// No description provided for @supportNewMessagesCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} tin mới'**
  String supportNewMessagesCount(int count);

  /// No description provided for @supportCreateTitle.
  ///
  /// In vi, this message translates to:
  /// **'Báo Cáo Sự Cố'**
  String get supportCreateTitle;

  /// No description provided for @supportCreateIssueTypeLabel.
  ///
  /// In vi, this message translates to:
  /// **'Loại sự cố gặp phải *'**
  String get supportCreateIssueTypeLabel;

  /// No description provided for @supportIssueOrder.
  ///
  /// In vi, this message translates to:
  /// **'Đơn hàng'**
  String get supportIssueOrder;

  /// No description provided for @supportIssuePayment.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán'**
  String get supportIssuePayment;

  /// No description provided for @supportIssueRestaurant.
  ///
  /// In vi, this message translates to:
  /// **'Quán ăn'**
  String get supportIssueRestaurant;

  /// No description provided for @supportIssueAppBug.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi ứng dụng'**
  String get supportIssueAppBug;

  /// No description provided for @supportIssueOther.
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get supportIssueOther;

  /// No description provided for @supportOrderIdRelatedLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mã đơn hàng liên quan (tùy chọn)'**
  String get supportOrderIdRelatedLabel;

  /// No description provided for @supportOrderIdRelatedHint.
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ: 1234'**
  String get supportOrderIdRelatedHint;

  /// No description provided for @supportIssueDescLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mô tả chi tiết sự cố *'**
  String get supportIssueDescLabel;

  /// No description provided for @supportIssueDescHint.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng mô tả rõ sự cố để nhân viên hỗ trợ bạn nhanh chóng nhất...'**
  String get supportIssueDescHint;

  /// No description provided for @supportIssueDescMinLength.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng mô tả sự cố (tối thiểu 5 ký tự)'**
  String get supportIssueDescMinLength;

  /// No description provided for @supportIssuePhotosLabel.
  ///
  /// In vi, this message translates to:
  /// **'Hình ảnh minh họa sự cố'**
  String get supportIssuePhotosLabel;

  /// No description provided for @supportIssuePhotosCount.
  ///
  /// In vi, this message translates to:
  /// **'{count}/3 ảnh'**
  String supportIssuePhotosCount(int count);

  /// No description provided for @supportAddPhoto.
  ///
  /// In vi, this message translates to:
  /// **'Thêm ảnh'**
  String get supportAddPhoto;

  /// No description provided for @supportCreateSubmitBtn.
  ///
  /// In vi, this message translates to:
  /// **'Gửi Báo Cáo & Bắt Đầu Chat'**
  String get supportCreateSubmitBtn;

  /// No description provided for @supportChatHeader.
  ///
  /// In vi, this message translates to:
  /// **'Hỗ trợ #{id}'**
  String supportChatHeader(int id);

  /// No description provided for @supportChatClosedNotice.
  ///
  /// In vi, this message translates to:
  /// **'Phiếu hỗ trợ này đã được đóng.'**
  String get supportChatClosedNotice;

  /// No description provided for @supportChatSenderYou.
  ///
  /// In vi, this message translates to:
  /// **'Bạn'**
  String get supportChatSenderYou;

  /// No description provided for @supportChatSenderAdmin.
  ///
  /// In vi, this message translates to:
  /// **'Admin Food Route'**
  String get supportChatSenderAdmin;

  /// No description provided for @supportChatStatusSeen.
  ///
  /// In vi, this message translates to:
  /// **'Đã xem'**
  String get supportChatStatusSeen;

  /// No description provided for @supportChatStatusSent.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi'**
  String get supportChatStatusSent;

  /// No description provided for @supportChatInputHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập tin nhắn hỗ trợ...'**
  String get supportChatInputHint;

  /// No description provided for @supportChatInputClosedHint.
  ///
  /// In vi, this message translates to:
  /// **'Phiếu hỗ trợ đã đóng'**
  String get supportChatInputClosedHint;

  /// No description provided for @orderTabProcessing.
  ///
  /// In vi, this message translates to:
  /// **'Đang xử lý'**
  String get orderTabProcessing;

  /// No description provided for @orderTabCompleted.
  ///
  /// In vi, this message translates to:
  /// **'Đã hoàn thành'**
  String get orderTabCompleted;

  /// No description provided for @orderCompletedCountBadge.
  ///
  /// In vi, this message translates to:
  /// **'{count} đơn hoàn tất'**
  String orderCompletedCountBadge(int count);

  /// No description provided for @orderEmptyProcessing.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có đơn hàng đang xử lý'**
  String get orderEmptyProcessing;

  /// No description provided for @orderStepPlaced.
  ///
  /// In vi, this message translates to:
  /// **'Đã đặt'**
  String get orderStepPlaced;

  /// No description provided for @orderStepConfirmed.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận'**
  String get orderStepConfirmed;

  /// No description provided for @orderStepPreparing.
  ///
  /// In vi, this message translates to:
  /// **'Chuẩn bị'**
  String get orderStepPreparing;

  /// No description provided for @orderStepReady.
  ///
  /// In vi, this message translates to:
  /// **'Chờ lấy'**
  String get orderStepReady;

  /// No description provided for @orderStepPickedUp.
  ///
  /// In vi, this message translates to:
  /// **'Đã lấy'**
  String get orderStepPickedUp;

  /// No description provided for @orderSelfPickup.
  ///
  /// In vi, this message translates to:
  /// **'Tự ghé lấy'**
  String get orderSelfPickup;

  /// No description provided for @orderTotalLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tổng tiền'**
  String get orderTotalLabel;

  /// No description provided for @orderCancelBtn.
  ///
  /// In vi, this message translates to:
  /// **'✕ Hủy đơn'**
  String get orderCancelBtn;

  /// No description provided for @orderStepTitlePlaced.
  ///
  /// In vi, this message translates to:
  /// **'Bước 1: Đã đặt món'**
  String get orderStepTitlePlaced;

  /// No description provided for @orderStepSubPlaced.
  ///
  /// In vi, this message translates to:
  /// **'Quán đang tiếp nhận'**
  String get orderStepSubPlaced;

  /// No description provided for @orderStepTitleConfirmed.
  ///
  /// In vi, this message translates to:
  /// **'Bước 2: Quán đã xác nhận'**
  String get orderStepTitleConfirmed;

  /// No description provided for @orderStepSubConfirmedPickup.
  ///
  /// In vi, this message translates to:
  /// **'Dự kiến lấy: {time}'**
  String orderStepSubConfirmedPickup(String time);

  /// No description provided for @orderStepSubConfirmedApproved.
  ///
  /// In vi, this message translates to:
  /// **'Quán đã duyệt đơn'**
  String get orderStepSubConfirmedApproved;

  /// No description provided for @orderStepTitlePreparing.
  ///
  /// In vi, this message translates to:
  /// **'Bước 3: Đang chuẩn bị'**
  String get orderStepTitlePreparing;

  /// No description provided for @orderStepSubPreparing.
  ///
  /// In vi, this message translates to:
  /// **'Bếp đang thực hiện'**
  String get orderStepSubPreparing;

  /// No description provided for @orderStepTitleReady.
  ///
  /// In vi, this message translates to:
  /// **'Bước 4: Sẵn sàng ghé lấy'**
  String get orderStepTitleReady;

  /// No description provided for @orderStepSubReady.
  ///
  /// In vi, this message translates to:
  /// **'Có thể đến lấy ngay'**
  String get orderStepSubReady;

  /// No description provided for @orderStatusBadgePickedUp.
  ///
  /// In vi, this message translates to:
  /// **'● Đã lấy'**
  String get orderStatusBadgePickedUp;

  /// No description provided for @orderStatusBadgeCancelled.
  ///
  /// In vi, this message translates to:
  /// **'● Đã hủy'**
  String get orderStatusBadgeCancelled;

  /// No description provided for @orderReviewBtn.
  ///
  /// In vi, this message translates to:
  /// **'Đánh giá'**
  String get orderReviewBtn;

  /// No description provided for @orderReviewedBtn.
  ///
  /// In vi, this message translates to:
  /// **'Đã đánh giá'**
  String get orderReviewedBtn;

  /// No description provided for @orderReorderBtn.
  ///
  /// In vi, this message translates to:
  /// **'Đặt lại'**
  String get orderReorderBtn;

  /// No description provided for @checkoutPreOrderTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận đơn Pre-Order'**
  String get checkoutPreOrderTitle;

  /// No description provided for @checkoutPickupTimeScheduled.
  ///
  /// In vi, this message translates to:
  /// **'Giờ hẹn nhận món'**
  String get checkoutPickupTimeScheduled;

  /// No description provided for @checkoutPayWithVietQR.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán qua VietQR / PayOS'**
  String get checkoutPayWithVietQR;

  /// No description provided for @checkoutDishSubtotal.
  ///
  /// In vi, this message translates to:
  /// **'Tiền món ăn'**
  String get checkoutDishSubtotal;

  /// No description provided for @checkoutDiscountWithCode.
  ///
  /// In vi, this message translates to:
  /// **'Giảm giá ({code})'**
  String checkoutDiscountWithCode(String code);

  /// No description provided for @checkoutDeliveryFee.
  ///
  /// In vi, this message translates to:
  /// **'Phí giao hàng'**
  String get checkoutDeliveryFee;

  /// No description provided for @checkoutFreeSelfPickup.
  ///
  /// In vi, this message translates to:
  /// **'0đ (Tự đến lấy)'**
  String get checkoutFreeSelfPickup;

  /// No description provided for @checkoutTotalPayment.
  ///
  /// In vi, this message translates to:
  /// **'Tổng thanh toán'**
  String get checkoutTotalPayment;

  /// No description provided for @checkoutCompleteOrder.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tất đặt món'**
  String get checkoutCompleteOrder;

  /// No description provided for @vietqrPaymentTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán VietQR / PayOS'**
  String get vietqrPaymentTitle;

  /// No description provided for @vietqrOrderCodeAmount.
  ///
  /// In vi, this message translates to:
  /// **'Mã đơn hàng: #DH-{id} • {amount}đ'**
  String vietqrOrderCodeAmount(String id, String amount);

  /// No description provided for @vietqrBank.
  ///
  /// In vi, this message translates to:
  /// **'Ngân hàng'**
  String get vietqrBank;

  /// No description provided for @vietqrAccountNumber.
  ///
  /// In vi, this message translates to:
  /// **'Số tài khoản'**
  String get vietqrAccountNumber;

  /// No description provided for @vietqrAccountName.
  ///
  /// In vi, this message translates to:
  /// **'Chủ tài khoản'**
  String get vietqrAccountName;

  /// No description provided for @vietqrTransferContent.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung CK'**
  String get vietqrTransferContent;

  /// No description provided for @vietqrExactMemoNotice.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng giữ chính xác nội dung chuyển khoản để hệ thống tự động xác nhận đơn.'**
  String get vietqrExactMemoNotice;

  /// No description provided for @vietqrAutoDetecting.
  ///
  /// In vi, this message translates to:
  /// **'Đang tự động nhận diện thanh toán...'**
  String get vietqrAutoDetecting;

  /// No description provided for @vietqrCancelOrderBtn.
  ///
  /// In vi, this message translates to:
  /// **'Hủy đơn hàng'**
  String get vietqrCancelOrderBtn;

  /// No description provided for @vietqrCancelDialogTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hủy đơn hàng?'**
  String get vietqrCancelDialogTitle;

  /// No description provided for @vietqrCancelDialogDesc.
  ///
  /// In vi, this message translates to:
  /// **'Đơn hàng #{id} ({amount}đ) sẽ bị hủy và không thể khôi phục.'**
  String vietqrCancelDialogDesc(String id, String amount);

  /// No description provided for @vietqrContinuePaymentBtn.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục thanh toán'**
  String get vietqrContinuePaymentBtn;

  /// No description provided for @vietqrConfirmCancelBtn.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận hủy'**
  String get vietqrConfirmCancelBtn;

  /// No description provided for @vietqrCancelFailed.
  ///
  /// In vi, this message translates to:
  /// **'Hủy đơn hàng thất bại. Vui lòng thử lại.'**
  String get vietqrCancelFailed;

  /// No description provided for @notifPeriodThisWeek.
  ///
  /// In vi, this message translates to:
  /// **'TUẦN NÀY'**
  String get notifPeriodThisWeek;

  /// No description provided for @notifTitlePaymentSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán thành công'**
  String get notifTitlePaymentSuccess;

  /// No description provided for @notifTitleOrderCompleted.
  ///
  /// In vi, this message translates to:
  /// **'Đơn hàng hoàn tất'**
  String get notifTitleOrderCompleted;

  /// No description provided for @notifTitleFoodReady.
  ///
  /// In vi, this message translates to:
  /// **'Món ăn đã sẵn sàng'**
  String get notifTitleFoodReady;

  /// No description provided for @notifTitleFoodPreparing.
  ///
  /// In vi, this message translates to:
  /// **'Đang chuẩn bị món'**
  String get notifTitleFoodPreparing;

  /// No description provided for @notifTitleOrderConfirmed.
  ///
  /// In vi, this message translates to:
  /// **'Đã xác nhận đơn hàng'**
  String get notifTitleOrderConfirmed;

  /// No description provided for @notifTitleOrderCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Đơn hàng đã hủy'**
  String get notifTitleOrderCancelled;

  /// No description provided for @notifTagPaid.
  ///
  /// In vi, this message translates to:
  /// **'Đã thanh toán'**
  String get notifTagPaid;

  /// No description provided for @notifTagPreparing.
  ///
  /// In vi, this message translates to:
  /// **'Đang chuẩn bị'**
  String get notifTagPreparing;

  /// No description provided for @notifTagReady.
  ///
  /// In vi, this message translates to:
  /// **'Sẵn sàng'**
  String get notifTagReady;

  /// No description provided for @notifTagCompleted.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tất'**
  String get notifTagCompleted;

  /// No description provided for @notifTagDelivering.
  ///
  /// In vi, this message translates to:
  /// **'Đang giao'**
  String get notifTagDelivering;

  /// No description provided for @notifTagCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Đã hủy'**
  String get notifTagCancelled;

  /// No description provided for @flashSaleTitle.
  ///
  /// In vi, this message translates to:
  /// **'Flash Sale Giá Sốc'**
  String get flashSaleTitle;

  /// No description provided for @flashSaleEndsIn.
  ///
  /// In vi, this message translates to:
  /// **'KẾT THÚC TRONG'**
  String get flashSaleEndsIn;

  /// No description provided for @flashSaleBannerSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'20 món ăn ngẫu nhiên • Làm mới mỗi 5 tiếng'**
  String get flashSaleBannerSubtitle;

  /// No description provided for @flashSalePrepTimeMin.
  ///
  /// In vi, this message translates to:
  /// **'{time}p'**
  String flashSalePrepTimeMin(int time);

  /// No description provided for @flashSaleSoldCount.
  ///
  /// In vi, this message translates to:
  /// **'Đã bán {count}'**
  String flashSaleSoldCount(int count);

  /// No description provided for @flashSaleSellingFast.
  ///
  /// In vi, this message translates to:
  /// **'Đang bán chạy'**
  String get flashSaleSellingFast;

  /// No description provided for @flashSaleRemaining.
  ///
  /// In vi, this message translates to:
  /// **'Còn lại {count}'**
  String flashSaleRemaining(int count);

  /// No description provided for @routeClearTraffic.
  ///
  /// In vi, this message translates to:
  /// **'Tuyến đường thông thoáng'**
  String get routeClearTraffic;

  /// No description provided for @routeClearTrafficDetail.
  ///
  /// In vi, this message translates to:
  /// **'Tuyến đường thông thoáng, không có ùn tắc'**
  String get routeClearTrafficDetail;

  /// No description provided for @routeTrafficStatusLabel.
  ///
  /// In vi, this message translates to:
  /// **'Giao thông: {status}'**
  String routeTrafficStatusLabel(String status);

  /// No description provided for @routeTrafficStatusDetail.
  ///
  /// In vi, this message translates to:
  /// **'Tình trạng giao thông: {status}'**
  String routeTrafficStatusDetail(String status);

  /// No description provided for @trafficStatusSmooth.
  ///
  /// In vi, this message translates to:
  /// **'Thông thoáng'**
  String get trafficStatusSmooth;

  /// No description provided for @trafficStatusSlow.
  ///
  /// In vi, this message translates to:
  /// **'Chậm'**
  String get trafficStatusSlow;

  /// No description provided for @trafficStatusModerate.
  ///
  /// In vi, this message translates to:
  /// **'Ùn tắc nhẹ'**
  String get trafficStatusModerate;

  /// No description provided for @trafficStatusHeavy.
  ///
  /// In vi, this message translates to:
  /// **'Ùn tắc nặng'**
  String get trafficStatusHeavy;

  /// No description provided for @routeDineInHeader.
  ///
  /// In vi, this message translates to:
  /// **'ĂN TẠI QUÁN'**
  String get routeDineInHeader;

  /// No description provided for @routePreOrderHeader.
  ///
  /// In vi, this message translates to:
  /// **'ĐẶT TRƯỚC'**
  String get routePreOrderHeader;

  /// No description provided for @routeQuickStopHeader.
  ///
  /// In vi, this message translates to:
  /// **'GHÉ LẤY'**
  String get routeQuickStopHeader;

  /// No description provided for @routeMinutesApprox.
  ///
  /// In vi, this message translates to:
  /// **'~{minutes} phút'**
  String routeMinutesApprox(int minutes);

  /// No description provided for @routeConvenientBadge.
  ///
  /// In vi, this message translates to:
  /// **'TIỆN ĐƯỜNG'**
  String get routeConvenientBadge;

  /// No description provided for @routeSearchingBadge.
  ///
  /// In vi, this message translates to:
  /// **'ĐANG TÌM'**
  String get routeSearchingBadge;

  /// No description provided for @routeStopoverBadge.
  ///
  /// In vi, this message translates to:
  /// **'GHÉ QUÁN'**
  String get routeStopoverBadge;

  /// No description provided for @routeZeroStoresBadge.
  ///
  /// In vi, this message translates to:
  /// **'0 QUÁN'**
  String get routeZeroStoresBadge;

  /// No description provided for @routeStopoverBanner.
  ///
  /// In vi, this message translates to:
  /// **'Điểm dừng ghé lấy: {storeName}'**
  String routeStopoverBanner(String storeName);

  /// No description provided for @routeSearchingFoodAlong.
  ///
  /// In vi, this message translates to:
  /// **'Đang tìm: \"{keyword}\" dọc tuyến đường...'**
  String routeSearchingFoodAlong(String keyword);

  /// No description provided for @routeNoStoresForKeyword.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy quán bán \"{keyword}\" dọc tuyến này'**
  String routeNoStoresForKeyword(String keyword);

  /// No description provided for @routeFoundStoresForKeyword.
  ///
  /// In vi, this message translates to:
  /// **'Tìm thấy {count} quán có \"{keyword}\" dọc tuyến'**
  String routeFoundStoresForKeyword(int count, String keyword);

  /// No description provided for @routeDefaultCommuteBanner.
  ///
  /// In vi, this message translates to:
  /// **'Tiện đường đi làm về • Đặt trước ghé lấy không chờ đợi'**
  String get routeDefaultCommuteBanner;

  /// No description provided for @routeConfirmDineIn.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận lộ trình ăn tại quán'**
  String get routeConfirmDineIn;

  /// No description provided for @routeConfirmPreOrder.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận lộ trình đặt trước'**
  String get routeConfirmPreOrder;

  /// No description provided for @routeConfirmQuickStop.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận lộ trình ghé lấy'**
  String get routeConfirmQuickStop;

  /// No description provided for @routeDirectionsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hướng dẫn đường đi'**
  String get routeDirectionsTitle;

  /// No description provided for @routeStepsCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} bước'**
  String routeStepsCount(int count);

  /// No description provided for @routeArriveAt.
  ///
  /// In vi, this message translates to:
  /// **'Đến {time}'**
  String routeArriveAt(String time);

  /// No description provided for @routeNoDirectionsData.
  ///
  /// In vi, this message translates to:
  /// **'Không có dữ liệu hướng dẫn'**
  String get routeNoDirectionsData;

  /// No description provided for @routeTrafficDelayed.
  ///
  /// In vi, this message translates to:
  /// **'Dự kiến trễ {delay} do giao thông'**
  String routeTrafficDelayed(String delay);

  /// No description provided for @routeGoStraight.
  ///
  /// In vi, this message translates to:
  /// **'Đi thẳng'**
  String get routeGoStraight;

  /// No description provided for @durationHoursMinutes.
  ///
  /// In vi, this message translates to:
  /// **'{hours} giờ {minutes} phút'**
  String durationHoursMinutes(int hours, int minutes);

  /// No description provided for @durationMinutes.
  ///
  /// In vi, this message translates to:
  /// **'{minutes} phút'**
  String durationMinutes(int minutes);

  /// No description provided for @trafficDelayMinutes.
  ///
  /// In vi, this message translates to:
  /// **'+{minutes} phút'**
  String trafficDelayMinutes(int minutes);

  /// No description provided for @trafficDelayHours.
  ///
  /// In vi, this message translates to:
  /// **'+{hours} giờ'**
  String trafficDelayHours(String hours);

  /// No description provided for @routeRestaurantsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Quán ăn trên lộ trình ({count})'**
  String routeRestaurantsTitle(int count);

  /// No description provided for @routeRestaurantsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tiện đường ghé lấy • Không cần đi vòng'**
  String get routeRestaurantsSubtitle;

  /// No description provided for @routeNoRestaurantsFound.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải hoặc chưa có quán ăn trực tiếp trên trục đường này'**
  String get routeNoRestaurantsFound;

  /// No description provided for @routeExploreFullMenu.
  ///
  /// In vi, this message translates to:
  /// **'Khám phá toàn bộ thực đơn'**
  String get routeExploreFullMenu;

  /// No description provided for @routeOnRoute.
  ///
  /// In vi, this message translates to:
  /// **'Ngay trên tuyến'**
  String get routeOnRoute;

  /// No description provided for @routeDetourMeters.
  ///
  /// In vi, this message translates to:
  /// **'Lệch tuyến {dist}m'**
  String routeDetourMeters(int dist);

  /// No description provided for @routePrepTimeApprox.
  ///
  /// In vi, this message translates to:
  /// **'Chuẩn bị ~{time} phút'**
  String routePrepTimeApprox(int time);

  /// No description provided for @routeDistanceLabel.
  ///
  /// In vi, this message translates to:
  /// **'Cách bạn: '**
  String get routeDistanceLabel;

  /// No description provided for @routeViewMenu.
  ///
  /// In vi, this message translates to:
  /// **'Xem Menu'**
  String get routeViewMenu;

  /// No description provided for @badgeNew.
  ///
  /// In vi, this message translates to:
  /// **'Mới'**
  String get badgeNew;

  /// No description provided for @restaurantDefaultName.
  ///
  /// In vi, this message translates to:
  /// **'Nhà hàng'**
  String get restaurantDefaultName;

  /// No description provided for @pickupAddressDefault.
  ///
  /// In vi, this message translates to:
  /// **'Địa chỉ tự đến lấy'**
  String get pickupAddressDefault;

  /// No description provided for @placeTypeLocation.
  ///
  /// In vi, this message translates to:
  /// **'Địa điểm'**
  String get placeTypeLocation;

  /// No description provided for @placeTypeRestaurant.
  ///
  /// In vi, this message translates to:
  /// **'Nhà hàng'**
  String get placeTypeRestaurant;

  /// No description provided for @placeTypeHotel.
  ///
  /// In vi, this message translates to:
  /// **'Khách sạn'**
  String get placeTypeHotel;

  /// No description provided for @placeTypeHospital.
  ///
  /// In vi, this message translates to:
  /// **'Bệnh viện'**
  String get placeTypeHospital;

  /// No description provided for @placeTypeSchool.
  ///
  /// In vi, this message translates to:
  /// **'Trường học'**
  String get placeTypeSchool;

  /// No description provided for @placeTypeCafe.
  ///
  /// In vi, this message translates to:
  /// **'Café'**
  String get placeTypeCafe;

  /// No description provided for @placeTypeBank.
  ///
  /// In vi, this message translates to:
  /// **'Ngân hàng'**
  String get placeTypeBank;

  /// No description provided for @placeTypePark.
  ///
  /// In vi, this message translates to:
  /// **'Công viên'**
  String get placeTypePark;

  /// No description provided for @placeTypeAirport.
  ///
  /// In vi, this message translates to:
  /// **'Sân bay'**
  String get placeTypeAirport;

  /// No description provided for @mapDirectionsHere.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ đường đến đây'**
  String get mapDirectionsHere;

  /// No description provided for @mapSetAsStart.
  ///
  /// In vi, this message translates to:
  /// **'Đặt làm điểm bắt đầu'**
  String get mapSetAsStart;

  /// No description provided for @mapCopiedCoordinates.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép tọa độ: {coord}'**
  String mapCopiedCoordinates(String coord);

  /// No description provided for @voucherAppliedCode.
  ///
  /// In vi, this message translates to:
  /// **'Đã áp dụng: {code}'**
  String voucherAppliedCode(String code);

  /// No description provided for @voucherDiscountAmount.
  ///
  /// In vi, this message translates to:
  /// **'Giảm giá: -{amount}'**
  String voucherDiscountAmount(String amount);

  /// No description provided for @voucherRemove.
  ///
  /// In vi, this message translates to:
  /// **'Gỡ bỏ'**
  String get voucherRemove;

  /// No description provided for @voucherAvailableTitle.
  ///
  /// In vi, this message translates to:
  /// **'Mã ưu đãi khả dụng'**
  String get voucherAvailableTitle;

  /// No description provided for @voucherNoAvailableFromStore.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có voucher khả dụng từ nhà hàng này'**
  String get voucherNoAvailableFromStore;

  /// No description provided for @voucherMinOrder.
  ///
  /// In vi, this message translates to:
  /// **'Đơn từ {amount}'**
  String voucherMinOrder(String amount);

  /// No description provided for @voucherAppliedStatus.
  ///
  /// In vi, this message translates to:
  /// **'Đã dùng'**
  String get voucherAppliedStatus;

  /// No description provided for @voucherNotEligibleStatus.
  ///
  /// In vi, this message translates to:
  /// **'Chưa đủ đơn'**
  String get voucherNotEligibleStatus;

  /// No description provided for @pickupDistanceAway.
  ///
  /// In vi, this message translates to:
  /// **'Cách {distance}'**
  String pickupDistanceAway(String distance);

  /// No description provided for @pickupInMinutes.
  ///
  /// In vi, this message translates to:
  /// **'Ghé lấy sau {minutes}p'**
  String pickupInMinutes(int minutes);

  /// No description provided for @routeDetails.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết'**
  String get routeDetails;

  /// No description provided for @routeViewSegmentDetails.
  ///
  /// In vi, this message translates to:
  /// **'Xem chi tiết chặng đường'**
  String get routeViewSegmentDetails;

  /// No description provided for @menuItemSoldOut.
  ///
  /// In vi, this message translates to:
  /// **'Hết món'**
  String get menuItemSoldOut;

  /// No description provided for @cartAddedSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã thêm \"{name}\" vào giỏ hàng'**
  String cartAddedSuccess(String name);

  /// No description provided for @itemSoldCount.
  ///
  /// In vi, this message translates to:
  /// **'Đã bán {count}'**
  String itemSoldCount(int count);

  /// No description provided for @voucherRemovedSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã gỡ voucher'**
  String get voucherRemovedSuccess;

  /// No description provided for @voucherAppliedSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã áp dụng mã {code} (Giảm {amount})'**
  String voucherAppliedSuccess(String code, String amount);

  /// No description provided for @voucherNetworkError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể xác minh mã voucher. Vui lòng kiểm tra lại mạng.'**
  String get voucherNetworkError;

  /// No description provided for @voucherDiscountPercent.
  ///
  /// In vi, this message translates to:
  /// **'Giảm {percent}%'**
  String voucherDiscountPercent(int percent);

  /// No description provided for @voucherDiscountPercentMax.
  ///
  /// In vi, this message translates to:
  /// **'Giảm {percent}% (Tối đa {maxAmount})'**
  String voucherDiscountPercentMax(int percent, String maxAmount);

  /// No description provided for @voucherDiscountFixed.
  ///
  /// In vi, this message translates to:
  /// **'Giảm {amount}'**
  String voucherDiscountFixed(String amount);

  /// No description provided for @paymentSuccessTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán thành công!'**
  String get paymentSuccessTitle;

  /// No description provided for @paymentSuccessSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Giao dịch của bạn đã được xác nhận. Cửa hàng sẽ sớm chuẩn bị món ăn.'**
  String get paymentSuccessSubtitle;

  /// No description provided for @paymentSuccessOrderId.
  ///
  /// In vi, this message translates to:
  /// **'Mã đơn hàng'**
  String get paymentSuccessOrderId;

  /// No description provided for @paymentSuccessAmount.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền thanh toán'**
  String get paymentSuccessAmount;

  /// No description provided for @paymentSuccessTime.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian'**
  String get paymentSuccessTime;

  /// No description provided for @paymentSuccessMethod.
  ///
  /// In vi, this message translates to:
  /// **'Phương thức'**
  String get paymentSuccessMethod;

  /// No description provided for @paymentSuccessVietQRMethod.
  ///
  /// In vi, this message translates to:
  /// **'VietQR / Ngân hàng'**
  String get paymentSuccessVietQRMethod;

  /// No description provided for @paymentSuccessCashMethod.
  ///
  /// In vi, this message translates to:
  /// **'Tiền mặt khi nhận'**
  String get paymentSuccessCashMethod;

  /// No description provided for @paymentSuccessViewRoute.
  ///
  /// In vi, this message translates to:
  /// **'Xem đường đi đến quán'**
  String get paymentSuccessViewRoute;

  /// No description provided for @paymentSuccessViewOrderDetails.
  ///
  /// In vi, this message translates to:
  /// **'Xem chi tiết đơn hàng'**
  String get paymentSuccessViewOrderDetails;

  /// No description provided for @stopoverDetailsTitle.
  ///
  /// In vi, this message translates to:
  /// **'CHI TIẾT ĐƠN GHÉ QUÁN'**
  String get stopoverDetailsTitle;

  /// No description provided for @stopoverOrderCode.
  ///
  /// In vi, this message translates to:
  /// **'Đơn #{orderCode}'**
  String stopoverOrderCode(String orderCode);

  /// No description provided for @stopoverLeg1ToStore.
  ///
  /// In vi, this message translates to:
  /// **'Chặng 1: Đến quán'**
  String get stopoverLeg1ToStore;

  /// No description provided for @stopoverLeg2ToDestination.
  ///
  /// In vi, this message translates to:
  /// **'Chặng 2: Đến điểm đích'**
  String get stopoverLeg2ToDestination;

  /// No description provided for @stopoverPickupScheduled.
  ///
  /// In vi, this message translates to:
  /// **'Hẹn lấy: {time}'**
  String stopoverPickupScheduled(String time);

  /// No description provided for @stopoverReturnOriginalRoute.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại tuyến gốc'**
  String get stopoverReturnOriginalRoute;

  /// No description provided for @stopoverCompleteTrip.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tất chuyến đi'**
  String get stopoverCompleteTrip;

  /// No description provided for @stopoverPickedUpContinue.
  ///
  /// In vi, this message translates to:
  /// **'Đã nhận món • Tiếp tục'**
  String get stopoverPickedUpContinue;

  /// No description provided for @stopoverPickedUpEnjoy.
  ///
  /// In vi, this message translates to:
  /// **'● Đã lấy món • Chúc bạn ngon miệng!'**
  String get stopoverPickedUpEnjoy;

  /// No description provided for @stopoverToStoreDistance.
  ///
  /// In vi, this message translates to:
  /// **'Đến quán: {info}'**
  String stopoverToStoreDistance(String info);

  /// No description provided for @stopoverViewDirections.
  ///
  /// In vi, this message translates to:
  /// **'Xem hướng dẫn đi'**
  String get stopoverViewDirections;

  /// No description provided for @stopoverMarkPickedUp.
  ///
  /// In vi, this message translates to:
  /// **'Đã lấy món'**
  String get stopoverMarkPickedUp;

  /// No description provided for @stopoverNavigateAgain.
  ///
  /// In vi, this message translates to:
  /// **'Hướng dẫn tới quán lại'**
  String get stopoverNavigateAgain;

  /// No description provided for @stopoverComplete.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tất'**
  String get stopoverComplete;

  /// No description provided for @stopoverMarkerOrderBadge.
  ///
  /// In vi, this message translates to:
  /// **'Đơn #{orderCode} • {storeName}'**
  String stopoverMarkerOrderBadge(String orderCode, String storeName);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
