//
//  ViewController.swift
//  JVSideMenu
//
//  Created by Vithiea Hor on 08/26/2021.
//  Copyright (c) 2021 horvithiea2@gmail.com. All rights reserved.
//

import UIKit
import JVSideMenu

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLeftSideMenu()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        JVSideMenu.shared.isGestureEnabled = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        JVSideMenu.shared.isGestureEnabled = false
    }
    
    private func setupLeftSideMenu() {
        let vc = self.storyboard!.instantiateViewController(withIdentifier: "LeftMenuTableViewController")
        JVSideMenu.shared.set(leftMenu: vc, rootController: self)
    }
    
    @IBAction func leftSideMenuAction() {
        JVSideMenu.shared.openLeft(completion: nil)
    }
}
