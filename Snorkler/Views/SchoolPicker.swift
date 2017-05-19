//
//  SchoolPicker.swift
//  Snorkler
//
//  Created by ナム Nam Nguyen on 5/19/17.
//  Copyright © 2017 Medigarage Studios LTD. All rights reserved.
//

import UIKit

protocol SchoolPickerDelegate {
    func schoolPicker(picker aPicker: SchoolPicker, schoolSelected school:School?)
}

class SchoolPicker: UIView, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var doneButton: UIButton!
    var schoolsData:Array<School> = [] {
        didSet{
            tableView.reloadData()
        }
    }
    private var selectedSchool:School?
    var delegate:SchoolPickerDelegate?
   
    override func awakeFromNib() {
        super.awakeFromNib()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    @IBAction func doneButtonDidTouch(_ sender: Any) {
        delegate?.schoolPicker(picker: self, schoolSelected: selectedSchool)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return schoolsData.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.001
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "school_cell")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "school_cell")
        }
        let school = schoolsData[indexPath.row]
        cell!.textLabel?.text = school.schoolName
        cell!.textLabel?.textColor = UIColor.colorWithHex(hex: 0x186f78)
        cell!.textLabel?.font = UIFont.systemFont(ofSize: 16)
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedSchool = schoolsData[indexPath.row]
    }
}
