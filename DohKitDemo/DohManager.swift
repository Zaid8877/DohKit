//
//  DohManager.swift
//  DohKitDemo
//
//  Created by Zaid Tayyab on 17/01/2024.
//

import Foundation
import NetworkExtension
import os.log

// Updated protocol with additional functions
public protocol DoHManagerProtocol {
    func didHandleNewFlow()
    func didStartDoHSuccessfully()
    func didFailToStartDoHWithError(_ error: Error)
    func didStopDoH()
}

enum DOHError: Error {
    case configurationError(NSError)
}

open class DOHManager: NSObject {
    private static let manager = NEDNSSettingsManager.shared()
    public var isConnected = false
    public var delegate: DoHManagerProtocol?

    public var servers: [String]
    public var serverUrl: String

    public init(isConnected: Bool = false, servers: [String], serverUrl: String) {
        self.isConnected = isConnected
        self.servers = servers
        self.serverUrl = serverUrl
    }

    // Updated to use asynchronous functions
    private func configureSettings() async -> Result<Void, DOHError> {
        let manager = NEDNSSettingsManager.shared()
        let setting = NEDNSOverTLSSettings(servers: self.servers)
        setting.serverName = serverUrl
        manager.dnsSettings = setting//server.configuration.toDNSSettings()
//        manager.onDemandRules = server.onDemandRules.toNEOnDemandRules()
        manager.saveToPreferences { saveError in
            if let saveError = saveError as NSError? {
                guard saveError.domain != "NEConfigurationErrorDomain"
                        || saveError.code != 9 else {
                    // Nothing was changed
                    return
                }
//                logger.error("\(saveError.localizedDescription)")
//                self.alert("Save Error", saveError.localizedDescription)
                self.removeSettings()
                print("failed")
                return
            }
            print("saved")
//            logger.debug("DNS settings was saved")
        }
        let settings = NEDNSOverHTTPSSettings(servers: servers)
        settings.serverURL = URL(string: serverUrl)!
        DOHManager.manager.dnsSettings = settings
        DOHManager.manager.localizedDescription = "DoH Proxy"
        DOHManager.manager.saveToPreferences { (error) in
            if let error = error {
                    print("Error loading preferences: \(error.localizedDescription)")
                    return
                }

                // Check if VPN is enabled
                if NEVPNManager.shared().isEnabled {
                    // VPN is enabled, handle accordingly
                } else {
                    // VPN is not enabled, request user permission
                    NEVPNManager.shared().isEnabled = true
                    NEVPNManager.shared().saveToPreferences(completionHandler: { error in
                        if let error = error {
                            print("Error saving preferences: \(error.localizedDescription)")
                            return
                        }

                        // Requesting VPN permission
                        NEVPNManager.shared().loadFromPreferences { loadError in
                            if let loadError = loadError {
                                print("Error loading preferences: \(loadError.localizedDescription)")
                            }
                        }
                    })
                }
            
        }
        
        do {
            try await DOHManager.manager.saveToPreferences()
            return .success(())
        } catch let error as NSError {
            if error.domain == "NEConfigurationErrorDomain" && error.code == 9 {
                print("success")
                return .success(())
            }
            print("catch failed")
            return .failure(.configurationError(error))
        }
    }
    private func removeSettings() {
//        self.usedID = nil

        #if !targetEnvironment(simulator)
            let manager = NEDNSSettingsManager.shared()
            guard manager.dnsSettings != nil else {
                // Already removed
                print("already removed")
                return
            }
            manager.removeFromPreferences { removeError in
//                self.updateStatus()
                if let removeError = removeError {
//                    logger.error("\(removeError.localizedDescription)")
//                    self.alert("Remove Error", removeError.localizedDescription)
                    print(removeError.localizedDescription)
                    return
                }
                print("removed")
//                logger.debug("DNS settings was removed")
            }
        #endif
    }

    // Updated to be asynchronous
    public func startDoH() async {
        os_log("Starting DOH!", log: .default, type: .info)

        switch await configureSettings() {
        case .success:
            isConnected = true
            os_log("DNS settings were saved", log: .default, type: .info)
            
            // Call the new protocol function when starting successfully
            delegate?.didStartDoHSuccessfully()
        case .failure(let error):
            isConnected = false
            os_log("Failed to configure DNS settings: %@", log: .default, type: .error, error.localizedDescription)
            print("failed")
            
            // Call the new protocol function when there's a failure
            delegate?.didFailToStartDoHWithError(error)
        }
    }

    // You can add a new function to stop the DOH service and call the corresponding protocol function
    public func stopDoH() {
        // Code to stop the DOH service
        
        // Call the new protocol function when stopping
        delegate?.didStopDoH()
    }
}
