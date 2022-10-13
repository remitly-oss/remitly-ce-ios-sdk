//
//  ViewController.swift
//  RemitlyCeExample
//
//  Created by Nick Hodapp on 8/25/22.
//

import UIKit
import RemitlyCEKit

class SendViewController_swift: UIViewController, RemitlyCeViewControllerDelegate {

    @IBOutlet var eventsLog: UITextView?
    
    private var timestamp: String {
        DateFormatter.localizedString(from: NSDate() as Date, dateStyle: .short, timeStyle: .medium)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        RemitlyCeConfiguration.loadConfig()
        RemitlyCeConfiguration.customerEmail = "nick+0618@remitly.com"
        
        if #available(iOS 15.0, *) {
            view.subviews
                .compactMap{ $0 as? UIButton }
                .forEach{ $0.configuration = UIButton.Configuration.filled() }
        }
    }
   
    @IBAction func onShowRemitly() {
        let remitlyCe = RemitlyCeViewController()
        remitlyCe.delegate = self

        self.present(remitlyCe, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let rvc = segue.destination as! RemitlyCeViewController
        rvc.delegate = self
    }
    
    func onUserActivity() {
        guard let eventsLog = eventsLog else {
            return
        }
        
        eventsLog.text = "\(timestamp) - onUserActivity\n" + eventsLog.text
    }
}

