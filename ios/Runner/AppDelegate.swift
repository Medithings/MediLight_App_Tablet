import UIKit
import Flutter
import UserNotifications
import flutter_background_service_ios
import alarm

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
        UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }
    SwiftAlarmPlugin.registerBackgroundTasks()
    
      let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
      let channel = FlutterMethodChannel(name: "ios_back_plugin", binaryMessenger: controller.binaryMessenger)
      
      channel.setMethodCallHandler{ call, result in
          if call.method == "letsGo"{
              result("Success")
              startBackgroundService()
          } else{
              result(FlutterMethodNotImplemented)
          }
      }
      
      func startBackgroundService(){
          DispatchQueue.global(qos: .background).async{
              // 여기서는 일단 true로 해서 무한으로 돌리지만 바꿔야함
//              while true{
//                  print("Background task is running...")
//                  sleep(30)
//              }
              print("Background task start")
          }
      }
      
      /// Disables background fetch
//      func cancelBackgroundTasks() {
//          if #available(iOS 13.0, *) {
//              BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: backgroundTaskIdentifier)
//          } else {
//              NSLog("SwiftAlarmPlugin: BGTaskScheduler not available for your version of iOS lower than 13.0")
//          }
//      }
//      
//      /// Enables background fetch
//      func scheduleAppRefresh() {
//          if #available(iOS 13.0, *) {
//              let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)
//
//              request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
//              do {
//                  try BGTaskScheduler.shared.submit(request)
//              } catch {
//                  NSLog("SwiftAlarmPlugin: Could not schedule app refresh: \(error)")
//              }
//          } else {
//              NSLog("SwiftAlarmPlugin: BGTaskScheduler not available for your version of iOS lower than 13.0")
//          }
//      }
      
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
