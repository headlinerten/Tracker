import Foundation
import AppMetricaCore

final class AnalyticsService {
    
    static func report(event: String, screen: String, item: String? = nil) {
        var params: [String: Any] = ["screen": screen]
        if let item = item {
            params["item"] = item
        }
        
        // Отправляем событие в AppMetrica
        AppMetrica.reportEvent(name: event, parameters: params) { error in
            print("ANALYTICS ERROR: Failed to report event '\(event)' with error: \(error.localizedDescription)")
        }
        
        // Дублируем в консоль для отладки
        print("ANALYTICS EVENT: '\(event)', PARAMS: \(params)")
    }
}
