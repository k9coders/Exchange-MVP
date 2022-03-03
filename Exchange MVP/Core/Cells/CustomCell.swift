//
//  CustomCollectionViewCell.swift
//  Exchange MVP
//
//  Created by Oleg Shum on 09.02.2022.
//

import UIKit

protocol CustomCellDelegate: AnyObject {
    func didEditTextTop(_ value: Double?)
    func didEditTextBottom(_ value: Double?)
}

final class CustomCell: UICollectionViewCell {
    
    static let reuseId = "CustomCell"
    
    var currencyNameLabel = UILabel()
    var currentBalanceLabel = UILabel()
    var exchangeRateLabel = UILabel()
    var amountTextField = UITextField()
    
    private var isTop = false
    
    weak var delegate: CustomCellDelegate?
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func textFieldDidChange() {
        let stringValue = amountTextField.text?.filter({ $0 != "-" && $0 != "+" })
        let value = Double(stringValue ?? "")
        if isTop {
            delegate?.didEditTextTop(value)
        } else {
            delegate?.didEditTextBottom(value)
        }
        guard let text = amountTextField.text else {
            return
        }
        let sign: Character = isTop ? "-" : "+"
        
        if text.count >= 1 {
            if text.first != sign {
                amountTextField.text = "\(sign)\(text)"
            } else {
                if text.count == 1 {
                    amountTextField.text = ""
                }
            }
        } else {
            amountTextField.text = ""
        }
    }
}

// MARK: - UITextFieldDelegate Impl
extension CustomCell: UITextFieldDelegate {

}
//MARK: - public method
extension CustomCell {
    
    func setupCell(with model: CellModel) {
        isTop = model.isTop
        currencyNameLabel.text = model.currency
        currentBalanceLabel.text = model.balance
        exchangeRateLabel.text = model.rate

        if let value = model.value {
            let sign: Character = isTop ? "-" : "+"
            amountTextField.text = "\(sign)\(String(format: "%.2f", value))"
        } else {
            amountTextField.text = nil
        }
    }
}

//MARK: - setup cells
private extension CustomCell {
    
    func setupView() {
        
        addSubview(currencyNameLabel)
        addSubview(currentBalanceLabel)
        addSubview(exchangeRateLabel)
        addSubview(amountTextField)
        
        backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.1)
        layer.cornerRadius = 15
        
        // currencyName setup
        currencyNameLabel.text = "000"
        currencyNameLabel.font = UIFont(name: "Futura-CondensedMedium", size: 80)
        currencyNameLabel.textColor = .black
        currencyNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        //currentBalance setup
        currentBalanceLabel.text = "You have: 100$"
        currentBalanceLabel.font = UIFont(name: "Futura-CondensedMedium", size: 20)
        currentBalanceLabel.textColor = .black
        currentBalanceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        //excchangeRate setup
        exchangeRateLabel.text = "$1 = $1"
        exchangeRateLabel.font = UIFont(name: "Futura-CondensedMedium", size: 20)
        exchangeRateLabel.textColor = .black
        exchangeRateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        //textFieldValue setup
        amountTextField.placeholder = "0.00"
        amountTextField.font = UIFont(name: "Futura-CondensedMedium", size: 80)
        amountTextField.textColor = .black
        amountTextField.translatesAutoresizingMaskIntoConstraints = false
        amountTextField.textAlignment = .right
        amountTextField.keyboardType = .numberPad
        amountTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        amountTextField.delegate =  self
    }
    
    func setConstraints() {
        
        let constraints = [
            currencyNameLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            currencyNameLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: 110),
            currencyNameLabel.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            
            currentBalanceLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            currentBalanceLabel.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            
            exchangeRateLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            exchangeRateLabel.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            
            amountTextField.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            amountTextField.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
        
    }
}
