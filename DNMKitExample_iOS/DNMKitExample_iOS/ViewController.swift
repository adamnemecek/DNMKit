//
//  ViewController.swift
//  DNMKitExample_iOS
//
//  Created by James Bean on 10/31/15.
//  Copyright © 2015 James Bean. All rights reserved.
//

import UIKit
import DNMConverter
import DNMUtility
import DNMModel
import DNMView
import DNMUI

// TODO: Reintegrate ViewSelector
class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var scoreTableView: UITableView!
    var scoreModelByTitle: [String : DNMScoreModel] = [:]
    var scoreTitles: [String] = []
    var environment: Environment!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        DNMColorManager.colorMode = ColorMode.Dark
        view.backgroundColor = DNMColorManager.backgroundColor


        scoreModelByTitle = DNMScoreModelManager().scoreModelByTitle()
        for (title, _) in scoreModelByTitle { scoreTitles.append(title) }

        scoreTableView = UITableView(frame: CGRect(x: 25, y: 25, width: 200, height: 300))
        scoreTableView.dataSource = self
        scoreTableView.delegate = self
        scoreTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        scoreTableView.tableFooterView = UIView(frame: CGRectZero)
        view.addSubview(scoreTableView)
    }
    
    func showScoreWithTitle(title: String) {
        
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        scoreTableView.deselectRowAtIndexPath(indexPath, animated: true)
        let cell = self.tableView(tableView, cellForRowAtIndexPath: indexPath)
        if let title = cell.textLabel?.text {
            if let scoreModel = scoreModelByTitle[title] {
                tableView.removeFromSuperview()
                self.environment = Environment(scoreModel: scoreModel)
                self.environment.build()
                view.addSubview(environment)
                addMenuButton()
            }
        }
    }
    
    func addMenuButton() {
        let menuButton = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 50))
        menuButton.setTitle("menu", forState: UIControlState.Normal)
        menuButton.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Normal)
        menuButton.setTitleColor(UIColor.redColor(), forState: UIControlState.Highlighted)
        menuButton.layer.position.y = view.frame.height - (0.5 * menuButton.frame.height)
        menuButton.layer.position.x = 0.5 * view.frame.width
        menuButton.addTarget(self, action: "goToMainPage", forControlEvents: .TouchUpInside)
        view.addSubview(menuButton)
        
    }
    
    func goToMainPage() {
        if environment.superview != nil { environment.removeFromSuperview() }
        view.addSubview(scoreTableView)
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scoreTitles.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath)
        -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell",
            forIndexPath: indexPath
        )
        let title = scoreTitles[indexPath.row]
        cell.textLabel?.text = title
        return cell
    }

    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

