//
//  Library
//
//  Created by Otto Suess on 21.08.18.
//  Copyright © 2018 Zap. All rights reserved.
//

import Foundation
import Lightning

final class RequestViewController: ModalDetailViewController {
    private weak var topSeparator: UIView?
    private weak var lightningButton: CallbackButton?
    private weak var orSeparator: UIView?
    private weak var onChainButton: CallbackButton?
    private weak var titleLabel: UILabel?
    private weak var amountInputView: AmountInputView?
    private weak var nextButton: CallbackButton?
    private weak var memoSeparator: UIView?
    private weak var memoTextField: UITextField?
    
    private var viewModel: RequestViewModel
    
    private var currentState = State.methodSelection {
        didSet {
            guard oldValue != currentState else { return }
            currentState.configure(viewController: self)
            updateHeight()
        }
    }
    
    private enum State {
        case methodSelection
        case amountInput
        case memoInput
        
        func configure(viewController: RequestViewController) {
            switch self {
            case .methodSelection:
                break
            case .amountInput:
                viewController.amountInputView?.becomeFirstResponder()
                viewController.amountInputView?.setKeypad(hidden: false, animated: true)
                viewController.topSeparator?.isHidden = false
                viewController.lightningButton?.isHidden = true
                viewController.orSeparator?.isHidden = true
                viewController.onChainButton?.isHidden = true
                viewController.amountInputView?.isHidden = false
                viewController.nextButton?.isHidden = false
                viewController.memoTextField?.isHidden = true
                viewController.memoSeparator?.isHidden = true
                viewController.nextButton?.button.setTitle("scene.request.next_button_title".localized, for: .normal)
            case .memoInput:
                viewController.amountInputView?.setKeypad(hidden: true, animated: true)
                viewController.memoTextField?.becomeFirstResponder()
                viewController.memoTextField?.isHidden = false
                viewController.memoSeparator?.isHidden = false
                viewController.nextButton?.button.setTitle("scene.request.generate_request_button".localized, for: .normal)
            }
        }
    }
    
    init(viewModel: RequestViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel = contentStackView.addArrangedElement(.label(text: "scene.request.title".localized, style: Style.Label.headline.with({ $0.textAlignment = .center }))) as? UILabel
        
        topSeparator = contentStackView.addArrangedElement(.separator)
        topSeparator?.isHidden = true
        
        setupRequestMethodSelection()
        
        let amountInputView = AmountInputView()
        amountInputView.backgroundColor = UIColor.Zap.background
        amountInputView.textColor = UIColor.Zap.white
        amountInputView.delegate = self
        amountInputView.addTarget(self, action: #selector(amountChanged(sender:)), for: .valueChanged)
        amountInputView.isHidden = true
        self.amountInputView = amountInputView
        contentStackView.addArrangedSubview(amountInputView)
        
        memoSeparator = contentStackView.addArrangedElement(.separator)
        memoSeparator?.isHidden = true
        let memoTextField = UITextField()
        Style.textField(color: UIColor.Zap.white).apply(to: memoTextField)
        memoTextField.backgroundColor = UIColor.Zap.background
        memoTextField.attributedPlaceholder = NSAttributedString(
            string: "generic.memo.placeholder".localized,
            attributes: [.foregroundColor: UIColor.Zap.gray]
        )
        contentStackView.addArrangedElement(.customHeight(30, element: .customView(memoTextField)))
        memoTextField.isHidden = true
        memoTextField.addTarget(self, action: #selector(updateMemo(sender:)), for: .editingChanged)
        self.memoTextField = memoTextField
        
        nextButton = contentStackView.addArrangedElement(.customHeight(56, element: .button(title: "scene.request.next_button_title".localized, style: Style.Button.background, completion: { [weak self] _ in
            self?.bottomButtonTapped()
        }))) as? CallbackButton
        nextButton?.isHidden = true
    }
    
    private func setupRequestMethodSelection() {
        let lightningImage = UIImage(named: "icon_request_lightning_button", in: .library, compatibleWith: nil)
        let lightningButtonStyle = Style.Button.background.with({
            $0.setImage(lightningImage, for: .normal)
            $0.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
        })
        lightningButton = contentStackView.addArrangedElement(.customHeight(56, element: .button(title: "scene.request.lightning_button".localized, style: lightningButtonStyle, completion: { [weak self] _ in
            self?.presentAmountInput(requestMethod: .lightning)
        }))) as? CallbackButton
        
        let horizontalStackView = UIStackView()
        horizontalStackView.spacing = 15
        horizontalStackView.axis = .horizontal
        horizontalStackView.distribution = .fill
        let leftSeparator = LineView()
        leftSeparator.backgroundColor = UIColor.Zap.background
        horizontalStackView.addArrangedSubview(leftSeparator)
        horizontalStackView.addArrangedElement(.label(text: "scene.request.or_separator_label".localized, style: Style.Label.body))
        let rightSeparator = LineView()
        rightSeparator.backgroundColor = UIColor.Zap.background
        horizontalStackView.addArrangedSubview(rightSeparator)
        contentStackView.addArrangedElement(.customView(horizontalStackView))
        leftSeparator.widthAnchor.constraint(equalTo: rightSeparator.widthAnchor, multiplier: 1, constant: 0).isActive = true
        self.orSeparator = horizontalStackView
        
        let onChainImage = UIImage(named: "icon_request_on_chain_button", in: .library, compatibleWith: nil)
        let onChainButtonStyle = Style.Button.background.with({
            $0.setImage(onChainImage, for: .normal)
            $0.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
        })
        onChainButton = contentStackView.addArrangedElement(.customHeight(56, element: .button(title: "scene.request.on_chain_button".localized, style: onChainButtonStyle, completion: { [weak self] _ in
            self?.presentAmountInput(requestMethod: .onChain)
        }))) as? CallbackButton
    }
    
    private func headerImage(for requestMethod: Layer) -> UIImage {
        let name: String
        switch requestMethod {
        case .lightning:
            name = "icon_header_lightning"
            titleLabel?.text = "scene.request.lightning_header_title".localized
        case .onChain:
            name = "icon_header_on_chain"
            titleLabel?.text = "scene.request.on_chain_header_title".localized
        }
        guard let image = UIImage(named: name, in: Bundle.library, compatibleWith: nil) else { fatalError("Image not found") }
        return image
    }
    
    private func presentAmountInput(requestMethod: Layer) {
        viewModel.requestMethod = requestMethod
        setHeaderImage(headerImage(for: requestMethod))
        currentState = .amountInput
    }
    
    private func bottomButtonTapped() {
        switch currentState {
        case .memoInput:
            presentPaymentRequest()
        case .amountInput:
            currentState = .memoInput
        default:
            return
        }
    }
    
    private func presentPaymentRequest() {
        viewModel.create { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let qrCodeDetailViewModel):
                    let viewController = UIStoryboard.instantiateQRCodeDetailViewController(with: qrCodeDetailViewModel)
                    self?.present(UINavigationController(rootViewController: viewController), animated: true) { [weak self] in
                        self?.setHeaderImage(nil)
                    }
                case .failure(let error):
                    self?.view.superview?.presentErrorToast(error.localizedDescription)
                }
            }
        }
    }
    
    @objc private func amountChanged(sender: AmountInputView) {
        viewModel.amount = sender.satoshis
    }
    
    @objc private func updateMemo(sender: UITextField) {
        viewModel.memo = sender.text
    }
}

extension RequestViewController: AmountInputViewDelegate {
    func amountInputViewDidBeginEditing(_ amountInputView: AmountInputView) {
        currentState = .amountInput
    }
    
    func amountInputViewDidEndEditing(_ amountInputView: AmountInputView) {}
}
