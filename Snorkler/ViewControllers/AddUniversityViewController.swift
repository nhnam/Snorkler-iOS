//
//  AddUniversityViewController.swift
//  Snorkler
//
//  Created by ナム Nam Nguyen on 5/16/17.
//  Copyright © 2017 Medigarage Studios LTD. All rights reserved.
//

import UIKit
import SwiftyJSON

struct School {
    var schoolId: String
    var schoolName: String
}

private enum InSchoolState:String {
    case none = "Unknown"
    case currentlyIn = "Currently in school"
    case notIn = "Not in school"
    case graduated = "Graduated"
}

class AddUniversityViewController: UIViewController {

    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var buttonImInSchool: UIButton!
    @IBOutlet weak var buttonImNotCurrent: UIButton!
    @IBOutlet weak var buttonImDone: UIButton!
    @IBOutlet weak var currentSchoolNameField: UITextField!
    @IBOutlet weak var graduatedSchoolNameField: UITextField!
    @IBOutlet weak var hasCurrentSchoolConstraint: NSLayoutConstraint?
    @IBOutlet weak var schoolPickerContainer: UIView!
    
    private var schoolsArray:Array<School> = []
    
    private var schoolPicker:SchoolPicker!
    private var frameOn:CGRect = .zero
    private var frameOff:CGRect = .zero
    
    internal var activeTextField:UITextField?
    
    private var schoolState:InSchoolState = .none {
        didSet{
            [currentSchoolNameField,graduatedSchoolNameField].forEach {
                $0?.isHidden = true
            }
            switch schoolState {
            case .currentlyIn:
                hasCurrentSchoolConstraint?.constant = 84
                buttonImInSchool.isSelected = true
                buttonImNotCurrent.isSelected = false
                buttonImDone.isSelected = false
                currentSchoolNameField.isHidden = false
                break
            case .notIn:
                hasCurrentSchoolConstraint?.constant = 20
                buttonImInSchool.isSelected = false
                buttonImNotCurrent.isSelected = true
                buttonImDone.isSelected = false
                break
            case .graduated:
                hasCurrentSchoolConstraint?.constant = 20
                buttonImInSchool.isSelected = false
                buttonImNotCurrent.isSelected = false
                buttonImDone.isSelected = true
                graduatedSchoolNameField.isHidden = false
                break
            case .none:
                hasCurrentSchoolConstraint?.constant = 20
                break
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        [currentSchoolNameField,graduatedSchoolNameField].forEach {
            $0?.layer.borderColor = UIColor.colorWithHex(hex: 0x186f78, alpha: 0.5).cgColor
            $0?.layer.cornerRadius = 2.0
            $0?.layer.backgroundColor = UIColor.white.cgColor
            $0?.layer.borderWidth = 1.5
            let leftView = UIView()
            leftView.frame = CGRect(x: 0, y: 0, width: 20, height: 30)
            leftView.backgroundColor = .clear
            $0?.leftView = leftView;
            $0?.leftViewMode = .always
            $0?.delegate = self
        }
        [buttonImInSchool,buttonImDone, buttonImNotCurrent].forEach {
            $0?.setImage(#imageLiteral(resourceName: "selected"), for: .selected)
            $0?.setImage(#imageLiteral(resourceName: "unselected"), for: .normal)
            $0?.addTarget(self, action: #selector(didCheckOption(_:)), for: .touchUpInside)
        }
        
        schoolPicker = Bundle.main.loadNibNamed("SchoolPicker", owner: self, options: nil)?.first as! SchoolPicker
        schoolPicker.delegate = self
        schoolPicker.clipsToBounds = true
        schoolPicker.layer.borderWidth = 1.0
        schoolPicker.layer.borderColor = UIColor.colorWithHex(hex: 0x186f78).cgColor
        schoolPicker.frame = schoolPickerContainer.bounds
        schoolPickerContainer.addSubview(schoolPicker)
        schoolPickerContainer.clipsToBounds = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        showLoading()
        
        ApiHelper.getSchools(onsuccess: { json in
            
            self.hideLoading()
            
            guard let resultJson = json as? JSON else { return }
            let interests:[JSON] = resultJson["schools"].arrayValue
            interests.forEach { itemJSON in
                let item = School(schoolId: itemJSON["school_id"].stringValue, schoolName: itemJSON["school_name"].stringValue)
                self.schoolsArray.append(item)
            }
            print(self.schoolsArray)
            DispatchQueue.main.async {
                self.schoolPicker.schoolsData = self.schoolsArray
                self.activeSchoolPicker(false)
            }

        }, onfailure: { errMsg in
            self.hideLoading()
            self.alert(errMsg ?? "")
        })
        
        hasCurrentSchoolConstraint?.constant = 20
        
        DispatchQueue.main.async {
            self.frameOn = self.schoolPickerContainer.frame
            self.frameOff = self.schoolPickerContainer.frame.offsetBy(dx: 0, dy: self.schoolPickerContainer.frame.size.height + 100)
            self.schoolPickerContainer.frame = self.frameOff
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        schoolState = .none
        schoolPickerContainer.translatesAutoresizingMaskIntoConstraints = true
    }
    
    internal func activeSchoolPicker(_ active: Bool) {
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0.0,
                       options: [UIViewAnimationOptions.beginFromCurrentState, UIViewAnimationOptions.curveEaseOut],
                       animations: {
                        self.schoolPickerContainer.frame = active ? self.frameOn : self.frameOff },
                       completion: { done in })
    }
    
    func didCheckOption(_ sender: UIButton) {
        if !sender.isSelected {
            sender.isSelected = true
        }
        if(sender == buttonImDone && sender.isSelected) {
            schoolState = .graduated
        }else if(sender == buttonImNotCurrent && sender.isSelected) {
            schoolState = .notIn
        }else if(sender == buttonImInSchool && sender.isSelected) {
            schoolState = .currentlyIn
        }
    }
    
    @IBAction func continueButtonDidTouch(_ sender: Any) {
        if schoolState == .currentlyIn && currentSchoolNameField.text == nil || schoolState == .graduated && graduatedSchoolNameField.text == nil{
            alert("Please enter school name")
            return
        }
        
        func onUpdateSuccess() {
            self.performSegue(withIdentifier: "toAddProfilePhoto", sender: self)
        }
        
        guard let member_id = AppSession.shared.userInfo?.memberId else { return }
        
        showLoading()
        
        var params:[String:Any] = ["member_id": member_id, "education_status":schoolState.rawValue]
        if schoolState == .currentlyIn{
            params["school_name"] = currentSchoolNameField.text ?? ""
        }
        if schoolState == .graduated{
            params["school_name"] = graduatedSchoolNameField.text ?? ""
        }
        
        ApiHelper.updateEducation(params: params, onsuccess: { (json) in
            self.hideLoading()
            onUpdateSuccess()
        }, onfailure: { errMsg in
            self.hideLoading()
        })
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension AddUniversityViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        activeTextField = textField
        self.activeSchoolPicker(true)
        return false
    }
}

extension AddUniversityViewController: SchoolPickerDelegate {
    func schoolPicker(picker aPicker: SchoolPicker, schoolSelected school: School?) {
        if let aSchool = school {
            activeTextField?.text = aSchool.schoolName
        }
        activeSchoolPicker(false)
    }
}
