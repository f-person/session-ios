import PromiseKit
import WebRTC
import SessionUIKit
import UIKit

extension AppDelegate {

    // MARK: Call handling
    @objc func handleAppActivatedWithOngoingCallIfNeeded() {
        guard let call = AppEnvironment.shared.callManager.currentCall else { return }
        if let callVC = CurrentAppContext().frontmostViewController() as? CallVC, callVC.call == call { return }
        guard let presentingVC = CurrentAppContext().frontmostViewController() else { preconditionFailure() } // TODO: Handle more gracefully
        let callVC = CallVC(for: call)
        if let conversationVC = presentingVC as? ConversationVC, let contactThread = conversationVC.thread as? TSContactThread, contactThread.contactSessionID() == call.sessionID {
            callVC.conversationVC = conversationVC
            conversationVC.inputAccessoryView?.isHidden = true
            conversationVC.inputAccessoryView?.alpha = 0
        }
        presentingVC.present(callVC, animated: true, completion: nil)
        
    }
    
    @objc func setUpCallHandling() {
        // Pre offer messages
        MessageReceiver.handlePreOfferCallMessage = { message in
            guard CurrentAppContext().isMainApp else { return }
            DispatchQueue.main.async {
                if let caller = message.sender, let uuid = message.uuid {
                    let call = SessionCall(for: caller, uuid: uuid, mode: .answer)
                    call.callMessageTimestamp = message.sentTimestamp
                    if CurrentAppContext().isMainAppAndActive {
                        guard let presentingVC = CurrentAppContext().frontmostViewController() else { preconditionFailure() } // TODO: Handle more gracefully
                        if let conversationVC = presentingVC as? ConversationVC, let contactThread = conversationVC.thread as? TSContactThread, contactThread.contactSessionID() == caller {
                            let callVC = CallVC(for: call)
                            callVC.conversationVC = conversationVC
                            conversationVC.inputAccessoryView?.isHidden = true
                            conversationVC.inputAccessoryView?.alpha = 0
                            presentingVC.present(callVC, animated: true, completion: nil)
                        }
                    }
                    call.reportIncomingCallIfNeeded{ error in
                        if let error = error {
                            SNLog("[Calls] Failed to report incoming call to CallKit due to error: \(error)")
                            let incomingCallBanner = IncomingCallBanner(for: call)
                            incomingCallBanner.show()
                        }
                    }
                }
                
            }
        }
        // Offer messages
        MessageReceiver.handleOfferCallMessage = { message in
            DispatchQueue.main.async {
                guard let call = AppEnvironment.shared.callManager.currentCall, message.uuid == call.uuid.uuidString else { return }
                let sdp = RTCSessionDescription(type: .offer, sdp: message.sdps![0])
                call.didReceiveRemoteSDP(sdp: sdp)
            }
        }
        // Answer messages
        MessageReceiver.handleAnswerCallMessage = { message in
            DispatchQueue.main.async {
                guard let callVC = CurrentAppContext().frontmostViewController() as? CallVC else { return }
                callVC.handleAnswerMessage(message)
            }
        }
        // End call messages
        MessageReceiver.handleEndCallMessage = { message in
            DispatchQueue.main.async {
                if let currentBanner = IncomingCallBanner.current { currentBanner.dismiss() }
                if let callVC = CurrentAppContext().frontmostViewController() as? CallVC { callVC.handleEndCallMessage(message) }
                if let miniCallView = MiniCallView.current { miniCallView.dismiss() }
                AppEnvironment.shared.callManager.reportCurrentCallEnded(reason: .remoteEnded)
            }
        }
    }
    
    // MARK: Configuration message
    @objc(syncConfigurationIfNeeded)
    func syncConfigurationIfNeeded() {
        guard Storage.shared.getUser()?.name != nil else { return }
        let userDefaults = UserDefaults.standard
        let lastSync = userDefaults[.lastConfigurationSync] ?? .distantPast
        guard Date().timeIntervalSince(lastSync) > 7 * 24 * 60 * 60,
            let configurationMessage = ConfigurationMessage.getCurrent() else { return } // Sync every 2 days
        let destination = Message.Destination.contact(publicKey: getUserHexEncodedPublicKey())
        Storage.shared.write { transaction in
            let job = MessageSendJob(message: configurationMessage, destination: destination)
            JobQueue.shared.add(job, using: transaction)
        }
        userDefaults[.lastConfigurationSync] = Date()
    }

    func forceSyncConfigurationNowIfNeeded() -> Promise<Void> {
        guard Storage.shared.getUser()?.name != nil,
            let configurationMessage = ConfigurationMessage.getCurrent() else { return Promise.value(()) }
        let destination = Message.Destination.contact(publicKey: getUserHexEncodedPublicKey())
        let (promise, seal) = Promise<Void>.pending()
        Storage.writeSync { transaction in
            MessageSender.send(configurationMessage, to: destination, using: transaction).done {
                seal.fulfill(())
            }.catch { _ in
                seal.fulfill(()) // Fulfill even if this failed; the configuration in the swarm should be at most 2 days old
            }.retainUntilComplete()
        }
        return promise
    }

    // MARK: Closed group poller
    @objc func startClosedGroupPoller() {
        guard OWSIdentityManager.shared().identityKeyPair() != nil else { return }
        ClosedGroupPoller.shared.start()
    }

    @objc func stopClosedGroupPoller() {
        ClosedGroupPoller.shared.stop()
    }
    
    // MARK: Theme
    @objc func getAppModeOrSystemDefault() -> AppMode {
        let userDefaults = UserDefaults.standard
        if userDefaults.dictionaryRepresentation().keys.contains("appMode") {
            let mode = userDefaults.integer(forKey: "appMode")
            return AppMode(rawValue: mode) ?? .light
        } else {
            if #available(iOS 13.0, *) {
                return UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .light
            } else {
                return .light
            }
        }
    }
}
