//
//  TextFieldElement.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/4/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

/**
 A generic text field whose logic is extracted into `TextFieldElementConfiguration`.
 
 - Seealso: `TextFieldElementConfiguration`
 */
final class TextFieldElement {
    
    // MARK: - Properties
    weak var delegate: ElementDelegate?
    var isOptional: Bool = false {
        didSet {
            textFieldView.updateUI(with: viewModel)
            delegate?.didUpdate(element: self)
        }
    }
    lazy var textFieldView: TextFieldView = {
        return TextFieldView(viewModel: viewModel, delegate: self)
    }()
    let configuration: TextFieldElementConfiguration
    private(set) lazy var text: String = {
        sanitize(text: configuration.defaultValue ?? "")
    }()
    var isEditing: Bool = false
    var validationState: ValidationState {
        return configuration.validate(text: text, isOptional: isOptional)
    }
    
    // MARK: - ViewModel

    struct ViewModel {
        struct KeyboardProperties {
            let type: UIKeyboardType
            let textContentType: UITextContentType?
            let autocapitalization: UITextAutocapitalizationType
        }
        
        var placeholder: String
        var text: String
        var attributedText: NSAttributedString
        var keyboardProperties: KeyboardProperties
        var isOptional: Bool
        var validationState: ValidationState
    }
    
    var viewModel: ViewModel {
        let placeholder: String = {
            if !isOptional {
                return configuration.label
            } else {
                let localized = STPLocalizedString(
                    "%@ (optional)",
                    "The label of a text field that is optional. For example, 'Email (optional)' or 'Name (optional)"
                )
                return String(format: localized, configuration.label)
            }
        }()
        return ViewModel(
            placeholder: placeholder,
            text: text,
            attributedText: configuration.makeDisplayText(for: text),
            keyboardProperties: configuration.keyboardProperties(for: text),
            isOptional: isOptional,
            validationState: validationState
        )
    }

    // MARK: - Initializer
    
    required init(configuration: TextFieldElementConfiguration) {
        self.configuration = configuration
    }
    
    // MARK: - Helpers
    
    func sanitize(text: String) -> String {
        return String(
            text.stp_stringByRemovingCharacters(from: configuration.disallowedCharacters)
            .prefix(configuration.maxLength)
        )
    }
}

// MARK: - Element

extension TextFieldElement: Element {
    func updateParams(params: IntentConfirmParams) -> IntentConfirmParams? {
        guard !view.isHidden, case .valid = validationState else {
            return nil
        }
        return configuration.updateParams(for: text, params: params)
    }

    var view: UIView {
        return textFieldView
    }
}

// MARK: - TextFieldViewDelegate

extension TextFieldElement: TextFieldViewDelegate {
    func didUpdate(view: TextFieldView) {
        // Update our state
        text = sanitize(text: view.text)
        isEditing = view.isEditing
        
        // Glue: Update the view and our delegate
        view.updateUI(with: viewModel)
        delegate?.didUpdate(element: self)
    }
    
    func didEndEditing(view: TextFieldView) {
        delegate?.didFinishEditing(element: self)
    }
}
