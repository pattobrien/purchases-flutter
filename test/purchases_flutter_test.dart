import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('purchases_flutter');
  final log = <MethodCall>[];
  dynamic response;
  final randomGenerator = Random(DateTime.now().microsecondsSinceEpoch);
  final mockCustomerInfoResponse = {
    'originalAppUserId': 'pepe',
    'entitlements': {'all': {}, 'active': {}},
    'activeSubscriptions': [],
    'latestExpirationDate': '2021-04-09T14:48:00.000Z',
    'allExpirationDates': {},
    'allPurchasedProductIdentifiers': [],
    'firstSeen': '2021-01-09T14:48:00.000Z',
    'requestDate': '2021-04-09T14:48:00.000Z',
    'allPurchaseDates': {},
    'originalApplicationVersion': '1.2.3',
    'nonSubscriptionTransactions': []
  };

  setUp(() {
    channel.setMockMethodCallHandler((call) async {
      log.add(call);
      return response;
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
    log.clear();
    response = null;
  });

  test('setupPurchases', () async {
    await Purchases.setup('api_key', appUserId: 'cesar', observerMode: true);
    expect(
      log,
      <Matcher>[
        isMethodCall(
          'setupPurchases',
          arguments: <String, dynamic>{
            'apiKey': 'api_key',
            'appUserId': 'cesar',
            'observerMode': true,
            'userDefaultsSuiteName': null
          },
        )
      ],
    );
  });

  test('getProductsList returns list of products', () async {
    response = [
      {
        'identifier': 'monthly_intro_pricing_one_week',
        'description': 'Monthly Product Intro Pricing One Week',
        'title': 'Monthly Product Intro Pricing One Week (PurchasesSample)',
        'price': 4.99,
        'price_string': '\$4.99',
        'currency_code': 'USD',
        'introPrice': {
          'price': 0,
          'priceString': '\$0.00',
          'period': 'P1W',
          'cycles': 1,
          'periodUnit': 'DAY',
          'periodNumberOfUnits': 7
        },
        'discounts': null,
        'intro_price': 0,
        'intro_price_string': '\$0.00',
        'intro_price_period': 'P1W',
        'intro_price_cycles': 1,
        'intro_price_period_unit': 'DAY',
        'intro_price_period_number_of_units': 7
      }
    ];
    final list = await Purchases.getProducts(['sku_a']);
    expect(list.length, 1);
  });

  test('checkTrialOrIntroductoryPriceEligibility returns eligibility map',
      () async {
    response = {
      'monthly_intro_pricing_one_week': {
        'status': 0,
        'description': 'Status indeterminate.'
      }
    };
    final list = await Purchases.checkTrialOrIntroductoryPriceEligibility(
      ['monthly_intro_pricing_one_week'],
    );
    expect(list.length, 1);
  });

  test('canMakePayments with no params calls successfully', () async {
    response = Random().nextBool();
    final receivedCanMakePayments = await Purchases.canMakePayments();

    expect(receivedCanMakePayments, response);
    expect(log, <Matcher>[
      isMethodCall('canMakePayments', arguments: {'features': []})
    ]);
  });

  test('canMakePayments with empty list calls successfully', () async {
    response = Random().nextBool();
    final receivedCanMakePayments = await Purchases.canMakePayments([]);

    expect(receivedCanMakePayments, response);
    expect(log, <Matcher>[
      isMethodCall('canMakePayments', arguments: {'features': []})
    ]);
  });

  test('canMakePayments with params calls successfully', () async {
    response = Random().nextBool();
    final receivedCanMakePayments =
        await Purchases.canMakePayments([BillingFeature.subscriptions]);

    expect(receivedCanMakePayments, response);
    expect(log, <Matcher>[
      isMethodCall(
        'canMakePayments',
        arguments: {
          'features': [0]
        },
      )
    ]);
  });

  test('canMakePayments params mapped to ordinals successfully', () async {
    response = Random().nextBool();
    final receivedCanMakePayments = await Purchases.canMakePayments([
      BillingFeature.subscriptions,
      BillingFeature.priceChangeConfirmation,
      BillingFeature.subscriptionsOnVr,
      BillingFeature.subscriptionsUpdate,
      BillingFeature.inAppItemsOnVr
    ]);

    expect(receivedCanMakePayments, response);
    expect(log, <Matcher>[
      isMethodCall(
        'canMakePayments',
        arguments: {
          'features': [0, 4, 3, 1, 2]
        },
      )
    ]);
  });

  test('logIn calls successfully', () async {
    try {
      final mockCreated = randomGenerator.nextBool();
      response = {
        'created': mockCreated,
        'customerInfo': mockCustomerInfoResponse
      };
      final logInResult = await Purchases.logIn('appUserID');
      expect(
        logInResult.customerInfo,
        CustomerInfo.fromJson(mockCustomerInfoResponse),
      );
      expect(logInResult.created, mockCreated);
    } on PlatformException catch (e) {
      fail('there was an exception ' + e.toString());
    }
  });

  test('logOut calls successfully', () async {
    try {
      response = mockCustomerInfoResponse;
      final customerInfo = await Purchases.logOut();
      expect(
        customerInfo,
        CustomerInfo.fromJson(mockCustomerInfoResponse),
      );
    } on PlatformException catch (e) {
      fail('there was an exception ' + e.toString());
    }
  });

  test('showManageSubscriptions calls successfully', () async {
    await Purchases.showManageSubscriptions();

    expect(log, <Matcher>[
      isMethodCall('showManageSubscriptions', arguments: null)
    ]);
  });

  test('beginRefundRequestForActiveEntitlement calls successfully', () async {
    response = {'status': RefundRequestStatus.success.index};
    final receivedStatus = await Purchases.beginRefundRequestForActiveEntitlement();
    expect(receivedStatus, RefundRequestStatusExtension.from(response['status']));

    expect(log, <Matcher>[
      isMethodCall('beginRefundRequestForActiveEntitlement', arguments: null)
    ]);
  });

  test('beginRefundRequestForProduct calls successfully', () async {
    const productID = 'asdf';
    response = {'status': RefundRequestStatus.success.index};
    final receivedStatus = await Purchases.beginRefundRequestForProduct(productID);

    expect(receivedStatus, RefundRequestStatusExtension.from(response['status']));
    expect(log, <Matcher>[
      isMethodCall('beginRefundRequestForProduct',
          arguments: {'productIdentifier': productID},)
    ]);
  });

  test('beginRefundRequestForEntitlement calls successfully', () async {
    const entitlementID = 'asdf';
    response = {'status': RefundRequestStatus.success.index};
    final receivedStatus =
      await Purchases.beginRefundRequestForEntitlement(entitlementID);

    expect(receivedStatus, RefundRequestStatusExtension.from(response['status']));
    expect(log, <Matcher>[
      isMethodCall('beginRefundRequestForEntitlement',
          arguments: {'entitlementIdentifier': entitlementID},)
    ]);
  });

  test('errors are mapped correctly', () {
    expect(PurchasesErrorCode.unknownError.index, 0);
    expect(PurchasesErrorCode.purchaseCancelledError.index, 1);
    expect(PurchasesErrorCode.storeProblemError.index, 2);
    expect(PurchasesErrorCode.purchaseNotAllowedError.index, 3);
    expect(PurchasesErrorCode.purchaseInvalidError.index, 4);
    expect(PurchasesErrorCode.productNotAvailableForPurchaseError.index, 5);
    expect(PurchasesErrorCode.productAlreadyPurchasedError.index, 6);
    expect(PurchasesErrorCode.receiptAlreadyInUseError.index, 7);
    expect(PurchasesErrorCode.invalidReceiptError.index, 8);
    expect(PurchasesErrorCode.missingReceiptFileError.index, 9);
    expect(PurchasesErrorCode.networkError.index, 10);
    expect(PurchasesErrorCode.invalidCredentialsError.index, 11);
    expect(PurchasesErrorCode.unexpectedBackendResponseError.index, 12);
    expect(PurchasesErrorCode.receiptInUseByOtherSubscriberError.index, 13);
    expect(PurchasesErrorCode.invalidAppUserIdError.index, 14);
    expect(PurchasesErrorCode.operationAlreadyInProgressError.index, 15);
    expect(PurchasesErrorCode.unknownBackendError.index, 16);
    expect(PurchasesErrorCode.invalidAppleSubscriptionKeyError.index, 17);
    expect(PurchasesErrorCode.ineligibleError.index, 18);
    expect(PurchasesErrorCode.insufficientPermissionsError.index, 19);
    expect(PurchasesErrorCode.paymentPendingError.index, 20);
    expect(PurchasesErrorCode.invalidSubscriberAttributesError.index, 21);
    expect(PurchasesErrorCode.logOutWithAnonymousUserError.index, 22);
    expect(PurchasesErrorCode.configurationError.index, 23);
    expect(PurchasesErrorCode.unsupportedError.index, 24);
    expect(PurchasesErrorCode.emptySubscriberAttributes.index, 25);
    expect(PurchasesErrorCode.productDiscountMissingIdentifierError.index, 26);
    expect(PurchasesErrorCode.missingAppUserIDForAliasCreationError.index, 27);
    expect(PurchasesErrorCode.productDiscountMissingSubscriptionGroupIdentifierError.index, 28);
    expect(PurchasesErrorCode.customerInfoError.index, 29);
    expect(PurchasesErrorCode.systemInfoError.index, 30);
    expect(PurchasesErrorCode.beginRefundRequestError.index, 31);
    expect(PurchasesErrorCode.productRequestTimedOut.index, 32);
    expect(PurchasesErrorCode.apiEndpointBlockedError.index, 33);
  });

  test('PurchasesErrorHelper maps errors correctly', () {
    expect(
      PurchasesErrorHelper.getErrorCode(PlatformException(code: '0')),
      PurchasesErrorCode.unknownError,
    );
    expect(
      PurchasesErrorHelper.getErrorCode(PlatformException(code: '1')),
      PurchasesErrorCode.purchaseCancelledError,
    );
    expect(
      PurchasesErrorHelper.getErrorCode(PlatformException(code: '2')),
      PurchasesErrorCode.storeProblemError,
    );
    expect(
      PurchasesErrorHelper.getErrorCode(PlatformException(code: '3')),
      PurchasesErrorCode.purchaseNotAllowedError,
    );
    expect(
      PurchasesErrorHelper.getErrorCode(PlatformException(code: '4')),
      PurchasesErrorCode.purchaseInvalidError,
    );
    expect(
      PurchasesErrorHelper.getErrorCode(PlatformException(code: '5')),
      PurchasesErrorCode.productNotAvailableForPurchaseError,
    );
    expect(
      PurchasesErrorHelper.getErrorCode(PlatformException(code: '6')),
      PurchasesErrorCode.productAlreadyPurchasedError,
    );
    expect(
      PurchasesErrorHelper.getErrorCode(PlatformException(code: '7')),
      PurchasesErrorCode.receiptAlreadyInUseError,
    );
    expect(
      PurchasesErrorHelper.getErrorCode(PlatformException(code: '8')),
      PurchasesErrorCode.invalidReceiptError,
    );
    expect(
      PurchasesErrorHelper.getErrorCode(PlatformException(code: '9')),
      PurchasesErrorCode.missingReceiptFileError,
    );
    expect(
      PurchasesErrorHelper.getErrorCode(PlatformException(code: '10')),
      PurchasesErrorCode.networkError,
    );
    expect(
      PurchasesErrorHelper.getErrorCode(PlatformException(code: '11')),
      PurchasesErrorCode.invalidCredentialsError,
    );
    expect(
      PurchasesErrorHelper.getErrorCode(PlatformException(code: '12')),
      PurchasesErrorCode.unexpectedBackendResponseError,
    );
    expect(
      PurchasesErrorHelper.getErrorCode(PlatformException(code: '13')),
      PurchasesErrorCode.receiptInUseByOtherSubscriberError,
    );
    expect(
      PurchasesErrorHelper.getErrorCode(PlatformException(code: '14')),
      PurchasesErrorCode.invalidAppUserIdError,
    );
    expect(
      PurchasesErrorHelper.getErrorCode(PlatformException(code: '15')),
      PurchasesErrorCode.operationAlreadyInProgressError,
    );
    expect(
      PurchasesErrorHelper.getErrorCode(PlatformException(code: '16')),
      PurchasesErrorCode.unknownBackendError,
    );
    expect(
      PurchasesErrorHelper.getErrorCode(PlatformException(code: '17')),
      PurchasesErrorCode.invalidAppleSubscriptionKeyError,
    );
    expect(
      PurchasesErrorHelper.getErrorCode(PlatformException(code: '18')),
      PurchasesErrorCode.ineligibleError,
    );
    expect(
      PurchasesErrorHelper.getErrorCode(PlatformException(code: '19')),
      PurchasesErrorCode.insufficientPermissionsError,
    );
    expect(
      PurchasesErrorHelper.getErrorCode(PlatformException(code: '20')),
      PurchasesErrorCode.paymentPendingError,
    );
    expect(
      PurchasesErrorHelper.getErrorCode(PlatformException(code: '21')),
      PurchasesErrorCode.invalidSubscriberAttributesError,
    );
    expect(
      PurchasesErrorHelper.getErrorCode(PlatformException(code: '22')),
      PurchasesErrorCode.logOutWithAnonymousUserError,
    );
    expect(
      PurchasesErrorHelper.getErrorCode(PlatformException(code: '23')),
      PurchasesErrorCode.configurationError,
    );
    expect(
      PurchasesErrorHelper.getErrorCode(PlatformException(code: '24')),
      PurchasesErrorCode.unsupportedError,
    );

    expect(
      PurchasesErrorHelper.getErrorCode(PlatformException(code: '25')),
      PurchasesErrorCode.emptySubscriberAttributes,
    );

    expect(
      PurchasesErrorHelper.getErrorCode(PlatformException(code: '26')),
      PurchasesErrorCode.productDiscountMissingIdentifierError,
    );

    expect(
      PurchasesErrorHelper.getErrorCode(PlatformException(code: '27')),
      PurchasesErrorCode.missingAppUserIDForAliasCreationError,
    );

    expect(
      PurchasesErrorHelper.getErrorCode(PlatformException(code: '28')),
      PurchasesErrorCode.productDiscountMissingSubscriptionGroupIdentifierError,
    );

    expect(
      PurchasesErrorHelper.getErrorCode(PlatformException(code: '29')),
      PurchasesErrorCode.customerInfoError,
    );

    expect(
      PurchasesErrorHelper.getErrorCode(PlatformException(code: '30')),
      PurchasesErrorCode.systemInfoError,
    );

    expect(
      PurchasesErrorHelper.getErrorCode(PlatformException(code: '31')),
      PurchasesErrorCode.beginRefundRequestError,
    );


    expect(
      PurchasesErrorHelper.getErrorCode(PlatformException(code: '32')),
      PurchasesErrorCode.productRequestTimedOut,
    );

    expect(
      PurchasesErrorHelper.getErrorCode(PlatformException(code: '33')),
      PurchasesErrorCode.apiEndpointBlockedError,
    );

    expect(
      PurchasesErrorHelper.getErrorCode(PlatformException(code: '100')),
      PurchasesErrorCode.unknownError,
    );

  });

  test('purchasePackage calls successfully', () async {
    try {
      response = {
        'productIdentifier': 'product.identifier',
        'customerInfo': mockCustomerInfoResponse
      };
      const mockStoreProduct = StoreProduct(
        'com.revenuecat.lifetime',
        'description',
        'lifetime (PurchasesSample)',
        199.99,
        '\$199.99',
        'USD',
      );
      const mockPackage = Package(
        '\$rc_lifetime',
        PackageType.lifetime,
        mockStoreProduct,
        'main',
      );
      final purchasePackageResult =
          await Purchases.purchasePackage(mockPackage);
      expect(
        purchasePackageResult,
        CustomerInfo.fromJson(mockCustomerInfoResponse),
      );
    } on PlatformException catch (e) {
      fail('there was an exception ' + e.toString());
    }
  });

  test('purchaseDiscountedPackage calls successfully', () async {
    try {
      response = {
        'productIdentifier': 'product.identifier',
        'customerInfo': mockCustomerInfoResponse
      };
      const mockStoreProduct = StoreProduct(
        'com.revenuecat.lifetime',
        'description',
        'lifetime (PurchasesSample)',
        199.99,
        '\$199.99',
        'USD',
      );
      const mockPackage = Package(
        '\$rc_lifetime',
        PackageType.lifetime,
        mockStoreProduct,
        'main',
      );
      const mockPaymentDiscount = PaymentDiscount(
        'aIdentifier',
        'aKeyIdentifier',
        'aNonce',
        'aSignature',
        123456,
      );
      final purchasePackageResult = await Purchases.purchaseDiscountedPackage(
        mockPackage,
        mockPaymentDiscount,
      );
      expect(
        purchasePackageResult,
        CustomerInfo.fromJson(mockCustomerInfoResponse),
      );
    } on PlatformException catch (e) {
      fail('there was an exception ' + e.toString());
    }
  });

  test('purchaseProduct calls successfully', () async {
    try {
      response = {
        'productIdentifier': 'product.identifier',
        'customerInfo': mockCustomerInfoResponse
      };
      const mockStoreProduct = StoreProduct(
        'com.revenuecat.lifetime',
        'description',
        'lifetime (PurchasesSample)',
        199.99,
        '\$199.99',
        'USD',
      );
      final purchasePackageResult =
          await Purchases.purchaseProduct(mockStoreProduct.identifier);
      expect(
        purchasePackageResult,
        CustomerInfo.fromJson(mockCustomerInfoResponse),
      );
    } on PlatformException catch (e) {
      fail('there was an exception ' + e.toString());
    }
  });

  test('purchaseDiscountedProduct calls successfully', () async {
    try {
      response = {
        'productIdentifier': 'product.identifier',
        'customerInfo': mockCustomerInfoResponse
      };
      const mockStoreProduct = StoreProduct(
        'com.revenuecat.lifetime',
        'description',
        'lifetime (PurchasesSample)',
        199.99,
        '\$199.99',
        'USD',
      );
      const mockPaymentDiscount = PaymentDiscount(
        'aIdentifier',
        'aKeyIdentifier',
        'aNonce',
        'aSignature',
        123456,
      );
      final purchasePackageResult = await Purchases.purchaseDiscountedProduct(
        mockStoreProduct,
        mockPaymentDiscount,
      );
      expect(
        purchasePackageResult,
        CustomerInfo.fromJson(mockCustomerInfoResponse),
      );
    } on PlatformException catch (e) {
      fail('there was an exception ' + e.toString());
    }
  });
}
