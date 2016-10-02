import Foundation

public protocol DiscordClientSpec : class, DiscordEngineClient {
	var guilds: [String: DiscordGuild] { get }
	var token: String { get }
	var user: DiscordUser? { get }

	init(token: String)

	func connect()
	func disconnect()
	func on(_ event: String, callback: @escaping ([Any]) -> Void)
}