//
//  AppDelegate.swift
//  TTGBingWallPaper
//
//  Created by tutuge on 16/8/28.
//  Copyright © 2016年 tutuge. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSSquareStatusItemLength)
    
    var autoUpdateMenuItem: NSMenuItem?
    var launchAtStartupMenuItem: NSMenuItem?
    
    @IBOutlet weak var window: NSWindow!
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Setup
        WallPaperSevice.sharedInstance.setup()
        
        // Update
        WallPaperSevice.sharedInstance.updateAndSetNewestBingWallPaper { (success) in}
        
        // Set Wake from sleep notification
        NSWorkspace.sharedWorkspace().notificationCenter.addObserver(self, selector:
            #selector(didWakeFromSleep), name: NSWorkspaceDidWakeNotification, object: nil)
        
        // Check if need update
        WallPaperSevice.sharedInstance.checkIfNeedUpdateWallPaper()
        
        // Setup UI
        configStatusButton()
        configMenuItems()
    }
    
    // MARK: Config
    
    func configStatusButton() {
        if let button = statusItem.button {
            button.image = NSImage(named: "menu_icon")
        }
    }
    
    func configMenuItems() {
        let menu = NSMenu()
        
        // Refresh newest wall paper
        menu.addItemWithTitle("Newest", action: #selector(menuItemNewestWallPaperClick), keyEquivalent: "n")
        
        // Refresh random wall paper
        menu.addItemWithTitle("Random", action: #selector(menuItemRandomWallPaperClick), keyEquivalent: "r")
        
        // Sub menu
        let subMenu = NSMenu()
        
        // Auto update
        autoUpdateMenuItem = NSMenuItem(title: "Auto Update", action: #selector(menuItemAutoUpdateClick), keyEquivalent: "")
        autoUpdateMenuItem?.toolTip = "Auto update newest Microsoft Bing Daily wallpaper."
        autoUpdateMenuItem?.onStateImage = NSImage(named: "checked")
        autoUpdateMenuItem?.offStateImage = nil
        updateAutoUpdateMenuItemState()
        subMenu.addItem(autoUpdateMenuItem!)
        
        // Launch at startup
        launchAtStartupMenuItem = NSMenuItem(title: "Launch at login", action: #selector(menuItemLaunchAtStartupClick), keyEquivalent: "")
        launchAtStartupMenuItem?.toolTip = "Config BingWallPaper launch at startup."
        launchAtStartupMenuItem?.onStateImage = NSImage(named: "checked")
        launchAtStartupMenuItem?.offStateImage = nil
        updateLaunchAtStartupMenuItemState()
        subMenu.addItem(launchAtStartupMenuItem!)
        
        // Open WallPaper folder
        subMenu.addItemWithTitle("History Wallpapers", action: #selector(menuItemOpenWallPapersFolderClick), keyEquivalent: "")
        
        // Copyright
        subMenu.addItemWithTitle("Copyright", action: #selector(menuItemCopyrightClick), keyEquivalent: "")
        
        // Github
        subMenu.addItemWithTitle("Github", action: #selector(menuItemGithubClick), keyEquivalent: "");
        
        // About
        subMenu.addItemWithTitle("About", action: #selector(menuItemAboutClick), keyEquivalent: "")
        
        // More
        let subMenuItem = NSMenuItem()
        subMenuItem.title = "More..."
        subMenuItem.submenu = subMenu
        menu.addItem(subMenuItem)
        
        // Quit
        menu.addItemWithTitle("Quit", action: #selector(menuItemQuitClick), keyEquivalent: "")
        
        statusItem.menu = menu
    }
    
    // MARK: Actions
    
    func menuItemLaunchAtStartupClick() {
        StartupHelper.toggleLaunchAtStartup()
        updateLaunchAtStartupMenuItemState()
        
        UserNotificationHelper.show("Config changed !", subTitle: "Launch at startup: \(StartupHelper.applicationIsInStartUpItems() ? "ON" : "OFF")", content: "")
    }
    
    func menuItemAutoUpdateClick() {
        let state = WallPaperSevice.sharedInstance.currentAutoUpadteSwitchState
        
        UserNotificationHelper.show("Config changed !", subTitle:  "Auto update: \(!state ? "ON" : "OFF")", content: "")
        
        WallPaperSevice.sharedInstance.currentAutoUpadteSwitchState = !state
        WallPaperSevice.sharedInstance.checkIfNeedUpdateWallPaper()
        
        updateAutoUpdateMenuItemState()
    }
    
    func menuItemNewestWallPaperClick() {
        WallPaperSevice.sharedInstance.updateAndSetNewestBingWallPaper { (success) in
            UserNotificationHelper.showWallPaperUpdateInfoWithModel()
        }
    }

    func menuItemRandomWallPaperClick() {
        WallPaperSevice.sharedInstance.updateAndSetRandomBingWallPaper { (success) in
            UserNotificationHelper.showWallPaperUpdateInfoWithModel()
        }
    }
    
    func menuItemOpenWallPapersFolderClick() {
        if let folderPath = WallPaperSevice.sharedInstance.imagesFolderLocation {
            NSWorkspace.sharedWorkspace().openURL(folderPath)
        }
    }
    
    func menuItemCopyrightClick() {
        if let copyrightUrl = NSURL(string: WallPaperSevice.sharedInstance.currentModel?.copyRightUrl ?? WallPaperAPIManager.BingHost) {
            NSWorkspace.sharedWorkspace().openURL(copyrightUrl)
        }
    }
    
    func menuItemGithubClick() {
        if let githubUrl = NSURL(string: "https://github.com/zekunyan/TTGBingWallPaper") {
            NSWorkspace.sharedWorkspace().openURL(githubUrl)
        }
    }
    
    func menuItemAboutClick() {
        let contentTextView = NSTextView()
        
        contentTextView.frame = CGRectMake(0, 0, 300, 60)
        contentTextView.string = "By tutuge.\nEmail: zekunyan@163.com\nGithub: https://github.com/zekunyan"
        contentTextView.sizeToFit()
        
        contentTextView.drawsBackground = false
        contentTextView.font = NSFont.systemFontOfSize(14)
        
        contentTextView.editable = true
        contentTextView.enabledTextCheckingTypes = NSTextCheckingAllTypes
        contentTextView.checkTextInDocument(nil)
        contentTextView.editable = false
        
        let alert = NSAlert()
        let version = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as! String

        alert.icon = NSImage(named: "AppIcon")
        alert.messageText = "BingWallPaper \(version)"
        alert.accessoryView = contentTextView
        alert.alertStyle = .InformationalAlertStyle
        alert.runModal()
    }
    
    func menuItemQuitClick() {
        NSApplication.sharedApplication().terminate(nil)
    }
    
    // MARK: NSWorkspaceDidWakeNotification
    
    @objc private func didWakeFromSleep() {
        WallPaperSevice.sharedInstance.checkIfNeedUpdateWallPaper()
    }
    
    // MARK: Private methods
    
    private func updateAutoUpdateMenuItemState() {
        autoUpdateMenuItem?.state = Int(WallPaperSevice.sharedInstance.currentAutoUpadteSwitchState)
    }
    
    private func updateLaunchAtStartupMenuItemState() {
        launchAtStartupMenuItem?.state = Int(StartupHelper.applicationIsInStartUpItems())
    }
}

