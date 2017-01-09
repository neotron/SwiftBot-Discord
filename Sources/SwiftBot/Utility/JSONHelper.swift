//
// Created by David Hedbor on 2017-01-08.
//

import Foundation
class JSON {
    static func from(string: String) -> NSDictionary?  {
        guard let data = string.data(using: .utf8) else {
            return nil
        }
        return from(data: data)
    }

    static func from(data: Data) ->  NSDictionary? {
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary
        } catch {
            LOG_ERROR(error.localizedDescription)
            return nil
        }
    }

    static func from(file: String) -> NSDictionary? {
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: file))
            return from(data: data)
        } catch {
            LOG_ERROR("Failed to load file into memory: \(file)")
            return nil
        }

    }


}
