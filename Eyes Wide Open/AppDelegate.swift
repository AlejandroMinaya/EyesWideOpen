//
//  AppDelegate.swift
//  Eyes Wide Open
//
//  Created by Juan Alcántara on 5/18/21.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet var window: NSWindow!
    private var filePath: String!
    
    @IBAction func chooseFile(button: NSObject) {
        let dialog = NSOpenPanel();
        dialog.allowedFileTypes = ["jpg","jpeg"]
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            let result = dialog.url
            
            if (result != nil) {
                filePath = result!.path
            }
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

