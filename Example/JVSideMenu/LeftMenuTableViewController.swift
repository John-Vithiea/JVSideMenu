//
//  LeftMenuTableViewController.swift
//  JVSideMenu_Example
//
//  Created by Vithiea Hor on 8/26/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UIKit
import JVSideMenu

class LeftMenuTableViewController: UITableViewController {
    
    let items = ["item 1", "item 2", "item 3", "item 4", "item 5"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.text = items[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vcToPush = self.storyboard!.instantiateViewController(withIdentifier: "itemDetailScreen")
        JVSideMenu.shared.push(vcToPush)
    }
}

