//
//  ShippingAddressViewControllerSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 6/15/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import FBSnapshotTestCase
@_spi(STP) @testable import Stripe
@_spi(STP) @testable import StripeCore
@_spi(STP) @testable import StripeUICore

class ShippingAddressViewControllerSnapshotTests: FBSnapshotTestCase {
    private let addressSpecProvider: AddressSpecProvider = {
        let specProvider = AddressSpecProvider()
        specProvider.addressSpecs = [
            "US": AddressSpec(format: "NOACSZ", require: "ACSZ", cityNameType: .city, stateNameType: .state, zip: "", zipNameType: .zip),
        ]
        return specProvider
    }()
    var configuration: PaymentSheet.Configuration {
        var config = PaymentSheet.Configuration()
        // Needed so that "Test Mode" banner appears
        config.apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        return config
    }
    
    override func setUp() {
        super.setUp()
//        self.recordMode = true
    }
    
    func testShippingAddressViewController() {
        let testWindow = UIWindow(frame: CGRect(x: 0, y: 0, width: 428, height: 500))
        testWindow.isHidden = false
        let vc = ShippingAddressViewController(
            addressSpecProvider: addressSpecProvider,
            configuration: configuration,
            delegate: self
        )
        let bottomSheetVC = PaymentSheet.FlowController.makeBottomSheetViewController(vc, configuration: vc.configuration)
        testWindow.rootViewController = bottomSheetVC
        verify(bottomSheetVC.view)
    }
    
    @available(iOS 13.0, *)
    func testShippingAddressViewController_darkMode() {
        let testWindow = UIWindow(frame: CGRect(x: 0, y: 0, width: 428, height: 500))
        testWindow.isHidden = false
        testWindow.overrideUserInterfaceStyle = .dark
        let vc = ShippingAddressViewController(
            addressSpecProvider: addressSpecProvider,
            configuration: configuration,
            delegate: self
        )
        let bottomSheetVC = PaymentSheet.FlowController.makeBottomSheetViewController(vc, configuration: vc.configuration)
        testWindow.rootViewController = bottomSheetVC
        verify(bottomSheetVC.view)
    }
    
    func testShippingAddressViewController_appearance() {
        let testWindow = UIWindow(frame: CGRect(x: 0, y: 0, width: 428, height: 500))
        testWindow.isHidden = false
        var configuration = configuration
        configuration.appearance = PaymentSheetTestUtils.snapshotTestTheme
        let vc = ShippingAddressViewController(
            addressSpecProvider: addressSpecProvider,
            configuration: configuration,
            delegate: self
        )
        let bottomSheetVC = PaymentSheet.FlowController.makeBottomSheetViewController(vc, configuration: vc.configuration)
        testWindow.rootViewController = bottomSheetVC
        verify(bottomSheetVC.view)
    }

    func verify(
        _ view: UIView,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        STPSnapshotVerifyView(view, identifier: identifier, file: file, line: line)
    }
}

extension ShippingAddressViewControllerSnapshotTests: ShippingAddressViewControllerDelegate {
    func shouldClose(_ viewController: ShippingAddressViewController) {
        // no-op
    }
}
