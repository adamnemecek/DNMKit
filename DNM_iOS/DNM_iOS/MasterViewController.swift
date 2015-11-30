//
//  MasterViewController.swift
//  DNM_iOS
//
//  Created by James Bean on 11/26/15.
//  Copyright © 2015 James Bean. All rights reserved.
//

import UIKit
import DNMModel
import Parse
import Bolts

// TODO: manage signed in / signed out: tableview.reloadData

class MasterViewController: UIViewController,
    UITableViewDelegate,
    UITableViewDataSource,
    UITextFieldDelegate
{
    // MARK: - UI
    
    @IBOutlet weak var scoreSelectorTableView: UITableView!
    
    @IBOutlet weak var colorModeLabel: UILabel!
    @IBOutlet weak var colorModeLightLabel: UILabel!
    @IBOutlet weak var colorModeDarkLabel: UILabel!
    
    @IBOutlet weak var loginStatusLabel: UILabel!
    @IBOutlet weak var signInOrOutOrUpButton: UIButton!
    @IBOutlet weak var signInOrUpButton: UIButton!
    
    @IBOutlet weak var dnmLogoLabel: UILabel!
    
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    // MARK: - Model
    
    private var scoreModelSelected: DNMScoreModel?
    
    // MARK: - Views
    
    // change to PerformerInterfaceView
    var viewByID: [String: PerformerView] = [:]
    var currentView: PerformerView?
    
    // don't make all of ScoreModel proporties top-level like in Envrionment
    
    // MARK: - Score Object Management
    
    var scoreObjects: [PFObject] = []
    
    var loginState: LoginState = .SignIn
    
    
    func createViews() {
        
    }
    
    // do this, instead, in tableView:didSelectCell...
    func goToViewWithID(id: String) {
        
    }
    
    
    // MARK: - Startup
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupScoreSelectorTableView()
        setupTextFields()
    }
    
    override func viewDidAppear(animated: Bool) {
        manageLoginStatus() // necessary to wait until viewDidAppear?
        fetchAllObjectsFromLocalDatastore()
        fetchAllObjects()
    }
    
    private func setupView() {
        updateUIForColorMode()
    }
    
    private func setupScoreSelectorTableView() {
        scoreSelectorTableView.delegate = self
        scoreSelectorTableView.dataSource = self
    }
    
    private func setupTextFields() {
        usernameField.delegate = self
        passwordField.delegate = self
    }
    
    // MARK: - UI
    
    @IBAction func didEnterUsername(sender: AnyObject) {
        
        // move on to password field
        passwordField.becomeFirstResponder()
    }
    
    
    @IBAction func didEnterPassword(sender: AnyObject) {
        
        if let username = usernameField.text, password = passwordField.text {
            
            // make sure its legit
            if username.characters.count > 0 && password.characters.count >= 8 {
                
                // disable keyboard
                passwordField.resignFirstResponder()
                
                
                // don't do this by the text of the button: enum LoginState { }
                switch signInOrOutOrUpButton.currentTitle! {
                case "SIGN UP":
                    let user = PFUser()
                    user.username = username
                    user.password = password
                    do {
                        try user.signUp()
                        enterSignedInMode()
                    }
                    catch {
                        print("could not sign up user")
                    }
                    
                case "SIGN IN":
                    do {
                        try PFUser.logInWithUsername(username, password: password)
                        enterSignedInMode()
                    }
                    catch {
                        print(error)
                    }
                default: break
                }
            }
        }
    }
    
    @IBAction func didPressSignInOrOutOrUpButton(sender: AnyObject) {
        print("sign in or out or up")
        
        // don't this by text
        
        if let title = signInOrOutOrUpButton.currentTitle {
            if title == "SIGN OUT?" {
                if PFUser.currentUser() != nil {
                    PFUser.logOutInBackground()
                    scoreObjects = []
                    scoreSelectorTableView.reloadData()
                    enterSignInMode()
                }
            }
        }
    }
    
    @IBAction func didPressSignInOrUpButton(sender: AnyObject) {
        if let title = signInOrUpButton.currentTitle {
            if title == "SIGN UP?" {
                enterSignUpmMode()
            } else if title == "SIGN IN?" {
                enterSignInMode()
            }
        }
    }
    
    
    @IBAction func didChangeValueOfSwitch(sender: UISwitch) {
        
        // state on = dark, off = light
        switch sender.on {
        case true: DNMColorManager.colorMode = ColorMode.Dark
        case false: DNMColorManager.colorMode = ColorMode.Light
        }
        updateUIForColorMode()
    }
    
    private func updateUIForColorMode() {
        view.backgroundColor = DNMColorManager.backgroundColor
        scoreSelectorTableView.reloadData()
        
        // enscapsulate
        let bgView = UIView()
        bgView.backgroundColor = DNMColorManager.backgroundColor
        scoreSelectorTableView.backgroundView = bgView
        
        loginStatusLabel.textColor = UIColor.grayscaleColorWithDepthOfField(.MiddleForeground)
        
        colorModeLabel.textColor = UIColor.grayscaleColorWithDepthOfField(.Foreground)
        colorModeLightLabel.textColor = UIColor.grayscaleColorWithDepthOfField(.Foreground)
        colorModeDarkLabel.textColor = UIColor.grayscaleColorWithDepthOfField(.Foreground)
        
        // textfields
        usernameField.backgroundColor = UIColor.grayscaleColorWithDepthOfField(.Background)
        usernameField.textColor = UIColor.grayscaleColorWithDepthOfField(.Foreground)
        passwordField.backgroundColor = UIColor.grayscaleColorWithDepthOfField(.Background)
        passwordField.textColor = UIColor.grayscaleColorWithDepthOfField(.Foreground)
        
        dnmLogoLabel.textColor = UIColor.grayscaleColorWithDepthOfField(.Foreground)
    }
    
    
    func updateLoginStatusLabel() {
        if let username = PFUser.currentUser()?.username {
            loginStatusLabel.hidden = false
            loginStatusLabel.text = "logged in as \(username)"
        } else {
            loginStatusLabel.hidden = true
        }
    }
    
    // MARK: - Parse Management
    
    func manageLoginStatus() {
        PFUser.currentUser() == nil ? enterSignInMode() : enterSignedInMode()
    }
    
    func enterSignInMode() {
        
        // hide score selector table view -- later: animate offscreen left
        scoreSelectorTableView.hidden = true
        
        signInOrOutOrUpButton.hidden = false
        signInOrOutOrUpButton.setTitle("SIGN IN", forState: .Normal)
        
        signInOrUpButton.hidden = false
        signInOrUpButton.setTitle("SIGN UP?", forState: .Normal)
        
        loginStatusLabel.hidden = true
        
        usernameField.hidden = false
        passwordField.hidden = false
    }
    
    // signed in
    func enterSignedInMode() {
        
        fetchAllObjectsFromLocalDatastore()
        fetchAllObjects()
        
        scoreSelectorTableView.hidden = false
        
        updateLoginStatusLabel()
        
        // hide username field, clear contents
        usernameField.hidden = true
        usernameField.text = nil
        
        // hide password field, clear contents
        passwordField.hidden = true
        passwordField.text = nil
        
        signInOrUpButton.hidden = true
        
        signInOrOutOrUpButton.hidden = false
        signInOrOutOrUpButton.setTitle("SIGN OUT?", forState: .Normal)
        
    }
    
    // need to sign up
    func enterSignUpmMode() {
        signInOrOutOrUpButton.setTitle("SIGN UP", forState: .Normal)
        signInOrUpButton.setTitle("SIGN IN?", forState: .Normal)
    }
    
    // MARK: - UITableViewDelegate Methods
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath)
        -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell",
            forIndexPath: indexPath
            ) as! ScoreSelectorTableViewCell
        
        // text
        cell.textLabel?.text = scoreObjects[indexPath.row]["title"] as? String
        
        // color
        cell.textLabel?.textColor = UIColor.grayscaleColorWithDepthOfField(.Foreground)
        cell.backgroundColor = UIColor.grayscaleColorWithDepthOfField(DepthOfField.Background)
        
        // make cleaner
        let selBGView = UIView()
        selBGView.backgroundColor = UIColor.grayscaleColorWithDepthOfField(.Middleground)
        cell.selectedBackgroundView = selBGView
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let scoreString = scoreObjects[indexPath.row]["text"] {
            let scoreModel = makeScoreModelWithString(scoreString as! String)
            scoreModelSelected = scoreModel
            performSegueWithIdentifier("showScore", sender: self)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let id = segue.identifier where id == "showScore" {
            let scoreViewController = segue.destinationViewController as! ScoreViewController
            if let scoreModel = scoreModelSelected {
                scoreViewController.showScoreWithScoreModel(scoreModel)
            }
        }
    }
    
    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView(frame: CGRectZero)
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scoreObjects.count
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - Parse
    
    func fetchAllObjectsFromLocalDatastore() {
        if let username = PFUser.currentUser()?.username {
            let query = PFQuery(className: "Score")
            query.fromLocalDatastore()
            query.whereKey("username", equalTo: username)
            query.findObjectsInBackgroundWithBlock { (objects, error) -> () in
                if let error = error { print(error) }
                else if let objects = objects {
                    self.scoreObjects = objects
                    self.scoreSelectorTableView.reloadData()
                }
            }
        }
    }
    
    func fetchAllObjects() {
        if let username = PFUser.currentUser()?.username {
            PFObject.unpinAllObjectsInBackground()
            let query = PFQuery(className: "Score")
            query.whereKey("username", equalTo: username)
            query.findObjectsInBackgroundWithBlock { (objects, error) -> () in
                
                if let objects = objects where error == nil {
                    self.scoreObjects = objects
                    do {
                        try PFObject.pinAll(objects)
                    }
                    catch {
                        print("couldnt pin")
                    }
                    self.fetchAllObjectsFromLocalDatastore()
                }
            }
        }
    }
    
    // MARK: - Model
    
    func makeScoreModelWithString(string: String) -> DNMScoreModel {
        let tokenizer = Tokenizer()
        let tokenContainer = tokenizer.tokenizeString(string)
        let parser = Parser()
        let scoreModel = parser.parseTokenContainer(tokenContainer)
        return scoreModel
    }
    
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
}

enum LoginState {
    case SignedIn, SignIn, SignUp
}
