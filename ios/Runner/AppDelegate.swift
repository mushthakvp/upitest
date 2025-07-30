
import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
    
    private var methodChannel: FlutterMethodChannel?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        
        // Setup method channel for payment communication
        methodChannel = FlutterMethodChannel(
            name: "upi_payment_channel",
            binaryMessenger: controller.binaryMessenger
        )
        
        // Handle method calls from Flutter
        methodChannel?.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            switch call.method {
            case "checkAppInstallation":
                if let args = call.arguments as? [String: Any],
                   let packageName = args["packageName"] as? String {
                    self?.checkAppInstallation(packageName: packageName, result: result)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
                }
            case "launchApp":
                if let args = call.arguments as? [String: Any],
                   let scheme = args["scheme"] as? String {
                    self?.launchApp(scheme: scheme, result: result)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
                }
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // Handle URL schemes when app returns from other apps
    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        
        // Handle payment response - Updated scheme
        if url.scheme == "upipaymentapp" && url.host == "upi" {
            handlePaymentResponse(url: url)
            return true
        }
        
        return super.application(app, open: url, options: options)
    }
    
    private func checkAppInstallation(packageName: String, result: @escaping FlutterResult) {
        // Map package names to iOS URL schemes
        let schemeMap: [String: String] = [
            "com.google.android.apps.nbu.paisa.user": "tez://", // Google Pay
            "com.phonepe.app": "phonepe://", // PhonePe
            "net.one97.paytm": "paytm://", // Paytm
            "in.amazon.mShop.android.shopping": "amazonpay://", // Amazon Pay
            "in.org.npci.upiapp": "bhim://", // BHIM
            "com.dreamplug.androidapp": "cred://", // CRED
            "com.paypal.ppmobile": "paypal://", // PayPal
            "apple.pay": "applepay://", // Apple Pay (always available)
            "web.payment": "https://", // Web payment (always available)
        ]
        
        // Special cases for always available options
        if packageName == "apple.pay" || packageName == "web.payment" {
            result(true)
            return
        }
        
        guard let scheme = schemeMap[packageName],
              let url = URL(string: scheme) else {
            result(false)
            return
        }
        
        let canOpen = UIApplication.shared.canOpenURL(url)
        result(canOpen)
    }
    
    private func launchApp(scheme: String, result: @escaping FlutterResult) {
        guard let url = URL(string: scheme) else {
            result(FlutterError(code: "INVALID_URL", message: "Invalid URL scheme", details: nil))
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:]) { success in
                result(success)
            }
        } else {
            result(FlutterError(code: "CANNOT_OPEN", message: "Cannot open URL", details: nil))
        }
    }
    
    private func handlePaymentResponse(url: URL) {
        var responseData: [String: String] = [:]
        
        // Parse URL components
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems {
            
            for item in queryItems {
                responseData[item.name] = item.value ?? ""
            }
        }
        
        let status = responseData["Status"] ?? responseData["status"] ?? "FAILURE"
        let txnId = responseData["txnId"] ?? responseData["ApprovalRefNo"] ?? ""
        let response = url.absoluteString
        
        // Send response back to Flutter
        methodChannel?.invokeMethod("onPaymentResponse", arguments: [
            "status": status,
            "txnId": txnId,
            "response": response
        ])
    }
}