//
//  AppDelegate.swift
//  TestSound
//
//  Created by Benedikt Terhechte on 03.04.19.
//  Copyright © 2019 Benedikt Terhechte. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    let gen = ToneGenerator()


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        gen.start()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        gen.stop()
    }


}

