//
//  sc_2App.swift
//  sc-2
//
//  Created by Brett Smith on 8/4/25.
//

import SwiftUI
import GoogleSignIn

@main
struct sc_2App: App {
    var body: some Scene {
        WindowGroup {
            AuthenticatedView()
                .onOpenURL { url in
                    // Handle Google Sign-In URL redirects
                    GIDSignIn.sharedInstance.handle(url)
                }
                .onAppear {
                    // Configure Google Sign-In
                    guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
                          let plist = NSDictionary(contentsOfFile: path),
                          let clientId = plist["CLIENT_ID"] as? String else {
                        // Fallback to Info.plist configuration
                        if let clientId = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String {
                            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
                        }
                        return
                    }
                    GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
                }
        }
    }
}
