//
//  IdentityImageUploaderTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 5/31/22.
//

import Foundation
import XCTest
@_spi(STP) import StripeCore
@testable import StripeIdentity

final class IdentityImageUploaderTest: XCTestCase {

    static let mockConfig = IdentityImageUploader.Configuration(
        filePurpose: "mock_purpose",
        highResImageCompressionQuality: 0.9,
        highResImageCropPadding: 0,
        highResImageMaxDimension: 600,
        lowResImageCompressionQuality: 0.8,
        lowResImageMaxDimension: 200
    )

    let mockImage = CapturedImageMock.frontDriversLicense.image.cgImage!

    var mockAPIClient: IdentityAPIClientTestMock!
    var uploader: IdentityImageUploader!

    override func setUp() {
        super.setUp()
        mockAPIClient = IdentityAPIClientTestMock(
            verificationSessionId: "VS_123",
            ephemeralKeySecret: "EAK_123"
        )
        uploader = IdentityImageUploader(
            configuration: IdentityImageUploaderTest.mockConfig,
            apiClient: mockAPIClient
        )
    }

    func testSetup() {
        // The config max dimensions must be smaller than the image size for
        // this test to be valid
        XCTAssertLessThan(IdentityImageUploaderTest.mockConfig.lowResImageMaxDimension, mockImage.width)
        XCTAssertLessThan(IdentityImageUploaderTest.mockConfig.lowResImageMaxDimension, mockImage.height)
        XCTAssertLessThan(IdentityImageUploaderTest.mockConfig.highResImageMaxDimension, mockImage.width)
        XCTAssertLessThan(IdentityImageUploaderTest.mockConfig.highResImageMaxDimension, mockImage.height)

        // This test also assumes that the test image is in portrait
        XCTAssertLessThan(mockImage.width, mockImage.height)
    }

    // Tests that JPEG is uploaded at the specified
    func testUploadJPEG() {
        let uploadRequestExpectations = mockAPIClient.makeUploadRequestExpectations(count: 1)
        let uploadResponseExp = expectation(description: "Upload completed")
        let fileName = "test_name"
        let compressionQuality: CGFloat = 0.1

        uploader.uploadJPEG(
            image: mockImage,
            fileName: fileName,
            jpegCompressionQuality: compressionQuality
        ).observe { result in
            switch result {
            case .failure(let error):
                XCTFail("Failed with \(error)")
            case .success(let stripeFile):
                XCTAssertEqual(stripeFile, DocumentUploaderTest.mockStripeFile)
            }
            uploadResponseExp.fulfill()
        }

        // Wait until request is made
        wait(for: uploadRequestExpectations, timeout: 1)

        // Verify request params match expected values
        XCTAssertEqual(mockAPIClient.imageUpload.requestHistory.count, 1)

        let uploadRequest = mockAPIClient.imageUpload.requestHistory.first
        XCTAssertNotNil(uploadRequest?.image)
        XCTAssertEqual(uploadRequest?.compressionQuality, compressionQuality)
        XCTAssertEqual(uploadRequest?.purpose, "mock_purpose")
        XCTAssertEqual(uploadRequest?.fileName, fileName)

        // Verify promise is observed after API responds to request
        mockAPIClient.imageUpload.respondToRequests(with: .success(DocumentUploaderTest.mockStripeFile))
        wait(for: [uploadResponseExp], timeout: 1)
    }

    func testUploadLowResImage() {
        let uploadRequestExpectations = mockAPIClient.makeUploadRequestExpectations(count: 1)

        uploader.uploadLowResImage(
            mockImage,
            fileName: "low-res-prefix_full_frame"
        ).observe { _ in
            // no-op
        }


        // Wait until request is made
        wait(for: uploadRequestExpectations, timeout: 1)

        guard let uploadRequest = mockAPIClient.imageUpload.requestHistory.first else {
            return XCTFail("Expected an upload request")
        }
        // Verify image has been resized correctly
        // (assumes original image is in portrait)
        XCTAssertEqual(uploadRequest.image.size.height, 200)
        XCTAssertLessThan(uploadRequest.image.size.width, 200)
        XCTAssertEqual(uploadRequest.compressionQuality, 0.8)
        XCTAssertEqual(uploadRequest.fileName, "low-res-prefix_full_frame")

        // Verify jpeg data is the expected size
        let (data, imageSize) = uploadRequest.image.jpegDataAndDimensions(maxBytes: nil, compressionQuality: 0.5)
        let imageFromData = UIImage(data: data)
        XCTAssertEqual(imageFromData?.scale, 1)
        XCTAssertEqual(imageFromData?.size, imageSize)
    }

    func testUploadHighResImageUncropped() {
        let uploadRequestExpectations = mockAPIClient.makeUploadRequestExpectations(count: 1)

        uploader.uploadHighResImage(
            mockImage,
            regionOfInterest: nil,
            cropPaddingComputationMethod: .maxImageWidthOrHeight,
            fileName: "high-res-prefix"
        ).observe { _ in
            // no-op
        }

        // Wait until request is made
        wait(for: uploadRequestExpectations, timeout: 1)

        guard let uploadRequest = mockAPIClient.imageUpload.requestHistory.first else {
            return XCTFail("Expected an upload request")
        }
        // Verify image has been resized correctly
        // (assumes original image is in portrait)
        XCTAssertEqual(uploadRequest.image.size.height, 600)
        XCTAssertLessThan(uploadRequest.image.size.width, 600)
        XCTAssertEqual(uploadRequest.compressionQuality, 0.9)
        XCTAssertEqual(uploadRequest.fileName, "high-res-prefix")

        // Verify jpeg data is the expected size
        let (data, imageSize) = uploadRequest.image.jpegDataAndDimensions(maxBytes: nil, compressionQuality: 0.5)
        let imageFromData = UIImage(data: data)
        XCTAssertEqual(imageFromData?.scale, 1)
        XCTAssertEqual(imageFromData?.size, imageSize)
    }

    func testUploadHighResImageCropped() {
        let uploadRequestExpectations = mockAPIClient.makeUploadRequestExpectations(count: 1)

        uploader.uploadHighResImage(
            mockImage,
            regionOfInterest: DocumentUploaderTest.mockRegionOfInterest,
            cropPaddingComputationMethod: .maxImageWidthOrHeight,
            fileName: "high-res-prefix"
        ).observe { _ in
            // no-op
        }

        // Wait until request is made
        wait(for: uploadRequestExpectations, timeout: 1)

        guard let uploadRequest = mockAPIClient.imageUpload.requestHistory.first else {
            return XCTFail("Expected an upload request")
        }
        // Verify image has been resized correctly
        // (assumes ROI is in landscape)
        XCTAssertLessThan(uploadRequest.image.size.height, 600)
        XCTAssertEqual(uploadRequest.image.size.width, 600)
        XCTAssertEqual(uploadRequest.compressionQuality, 0.9)
        XCTAssertEqual(uploadRequest.fileName, "high-res-prefix")

        // Verify jpeg data is the expected size
        let (data, imageSize) = uploadRequest.image.jpegDataAndDimensions(maxBytes: nil, compressionQuality: 0.5)
        let imageFromData = UIImage(data: data)
        XCTAssertEqual(imageFromData?.scale, 1)
        XCTAssertEqual(imageFromData?.size, imageSize)
    }
}
