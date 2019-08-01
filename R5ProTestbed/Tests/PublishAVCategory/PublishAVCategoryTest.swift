//
//  PublishAVCategoryTest.swift
//  R5ProTestbed
//
//  **** FOR KIWIUP-27 ****
//

import UIKit
import R5Streaming

@objc(PublishAVCategoryTest)
class PublishAVCategoryTest: BaseTest {
    
    var toggled : Bool = false
    
    override func viewDidAppear(_ animated: Bool) {

        super.viewDidAppear(animated)
        
        AVAudioSession.sharedInstance().requestRecordPermission { (gotPerm: Bool) -> Void in
           
        };
        
        setupDefaultR5VideoViewController()
        
        // Set up the configuration
        let config = getConfig()
        config.inheritAVSessionOptions = false
        
        let session : AVAudioSession = AVAudioSession.sharedInstance()
        do {

            let optionVal = AVAudioSession.CategoryOptions(rawValue: AVAudioSession.CategoryOptions.RawValue(UInt8(AVAudioSession.CategoryOptions.mixWithOthers.rawValue) | UInt8(AVAudioSession.CategoryOptions.allowBluetooth.rawValue) | UInt8(AVAudioSession.CategoryOptions.defaultToSpeaker.rawValue)))
            
            if #available(iOS 10.0, *) {
                try session.setCategory(AVAudioSession.Category.playAndRecord, mode:.default, options: optionVal)
            } else {
                // Fallback on earlier versions
                // This would require session.setCategory(_:) or session.setCategory(_:options:) which are available to iOS6+
                // However, neither are available in Swift 4, and so either require a bridge through Objective C
                try AVAudioSessionSuplement.setCategory(session, category:.playAndRecord, options: optionVal)
            }

            try session.setActive(true)

        }
        catch let error as NSError {
            NSLog(error.localizedFailureReason!)
        }
        
        // Set up the connection and stream
        let connection = R5Connection(config: config)
        
        setupPublisher(connection: connection!)
        // show preview and debug info
       // self.publishStream?.getVideoSource().fps = 2;
        self.currentView!.attach(publishStream!)
        
        self.publishStream!.publish(Testbed.getParameter(param: "stream1") as! String, type: R5RecordTypeLive)

    }
    
    override func onR5StreamStatus(_ stream: R5Stream!, withStatus statusCode: Int32, withMessage msg: String!) {
        super.onR5StreamStatus(stream, withStatus: statusCode, withMessage: msg)
        if( Int(statusCode) == Int(r5_status_start_streaming.rawValue) ){

            let session : AVAudioSession = AVAudioSession.sharedInstance()
            let cat = session.category
            let opt = session.categoryOptions
            
            let s =  String(format: "AV: %@ (%d)",  cat.rawValue, opt.rawValue)
            ALToastView.toast(in: self.view, withText:s)
            
        }
        else if (Int(statusCode) == Int(r5_status_buffer_flush_start.rawValue)) {
            NotificationCenter.default.post(Notification(name: Notification.Name("BufferFlushStart")))
        }
        else if (Int(statusCode) == Int(r5_status_buffer_flush_empty.rawValue)) {
            NotificationCenter.default.post(Notification(name: Notification.Name("BufferFlushComplete")))
        }
    }
}
