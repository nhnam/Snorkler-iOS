//
//  AddInterestViewController.swift
//  Snorkler
//
//  Created by ナム Nam Nguyen on 5/16/17.
//  Copyright © 2017 Medigarage Studios LTD. All rights reserved.
//

import UIKit
import JCTagListView
import UIColor_Hex
import SwiftyJSON

struct Interest {
    var interestId: String
    var interestName: String
}

class AddInterestViewController: UIViewController {

    @IBOutlet weak var srollview: UIScrollView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var tagsView: JCTagListView!
    @IBOutlet weak var continueButton: UIButton!
    private var interestsArray:Array<Interest> = []
    private var selectedInterestsArray:Array<Interest> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getTrendingInterests()
    }
    
    private func getTrendingInterests() {
        showLoading()
        ApiHelper.getTrendingInterests(onsuccess: { result in
            print(result)
            self.hideLoading()
            guard let resultJson = result as? JSON else { return }
            let interests:[JSON] = resultJson["interests"].arrayValue
            interests.forEach { itemJSON in
                let item = Interest(interestId: itemJSON["interest_id"].stringValue,
                                    interestName: itemJSON["interest_name"].stringValue)
                self.interestsArray.append(item)
            }
            DispatchQueue.main.async {
                self.setupTags()
            }
        }, onfailure: { err in
            print("\(String(describing: err))")
            self.hideLoading()
        })
    }

    private func setupTags() {
        tagsView.canSelectTags = true
        tagsView.tagSelectedTextColor = .black
        let tags = interestsArray.map{ $0.interestName }
        tagsView.tags = NSMutableArray(array: tags)
        tagsView.selectedTags = []
        tagsView.tagCornerRadius = 2.0
        tagsView.tagStrokeColor = UIColor(hex:0x1A95D6)
        tagsView.tagTextColor = UIColor(hex:0x1A95D6)
        tagsView.setCompletionBlockWithSelected { index in
            self.selectedInterestsArray.append(self.interestsArray[index])
        }
        tagsView.collectionView.reloadData()
    }
    
    @IBAction func continueButtonDidTouch(_ sender: Any) {
        func onUpdateSuccess() {
            self.performSegue(withIdentifier: "toAddUniversity", sender: self)
        }
        let tags:[String] = selectedInterestsArray.map{ $0.interestId }
        let listIds:String = tags.joined(separator: ",")
        let params:[String:Any] = ["member_id":AppSession.shared.userInfo?.memberId ?? "", "interes_list":listIds]
        showLoading()
        ApiHelper.updateInterests(params: params, onsuccess: { json in
            self.hideLoading()
            onUpdateSuccess()
        }) { (err) in
            print("\(String(describing: err))")
            self.hideLoading()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    
}
