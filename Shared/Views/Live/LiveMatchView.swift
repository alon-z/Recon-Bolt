import SwiftUI
import ValorantAPI

struct LiveMatchView: View {
	let gameInfo: LiveGameInfo
	let user: User
	
	let ownPlayer: LiveGameInfo.PlayerInfo
	
	init(gameInfo: LiveGameInfo, user: User) {
		self.gameInfo = gameInfo
		self.user = user
		
		ownPlayer = gameInfo.players.first { $0.id == user.id }!
	}
	
	var body: some View {
		ScrollView {
			VStack(spacing: 0) {
				hero
				
				playerList
			}
		}
	}
	
	@ViewBuilder
	private var hero: some View {
		ZStack {
			MapImage.splash(gameInfo.mapID)
				.aspectRatio(contentMode: .fill)
				.frame(height: 200)
				.clipped()
				.overlay(MapImage.Label(mapID: gameInfo.mapID).padding(6))
			
			VStack(spacing: 10) {
				if let queueID = gameInfo.matchmakingData.queueID {
					Text(queueID.name)
						.fontWeight(.medium)
						.foregroundStyle(.secondary)
				}
			}
			.padding()
			.background(Material.thin)
			.cornerRadius(8)
			.shadow(radius: 10)
		}
	}
	
	@ViewBuilder
	private var playerList: some View {
		let teams = Dictionary(grouping: gameInfo.players, by: \.teamID)
		let allyTeam = teams[ownPlayer.teamID]!
		let enemyTeams = teams
			.filter { $0.key != ownPlayer.teamID }
			.sorted(on: \.key.description)
		
		VStack(spacing: 10) {
			ForEach(allyTeam) {
				PlayerView(player: $0, ownPlayer: ownPlayer)
			}
			
			ForEach(enemyTeams, id: \.key) { teamID, team in
				Divider()
					.padding(.vertical, 5)
				
				ForEach(team) {
					PlayerView(player: $0, ownPlayer: ownPlayer)
				}
			}
		}
		.padding()
	}
	
	struct PlayerView: View {
		let player: LiveGameInfo.PlayerInfo
		let ownPlayer: LiveGameInfo.PlayerInfo
		
		@State var playerUser: User?
		@State var summary: CompetitiveSummary?
		@Environment(\.assets) private var assets
		
		var body: some View {
			let isAlly = player.teamID == ownPlayer.teamID
			let isSelf = player.id == ownPlayer.id
			let teamColor: Color = isAlly ? .valorantBlue : .valorantRed
			let relativeColor = isSelf ? .valorantSelf : teamColor
			let iconSize = 48.0
			
			HStack {
				AgentImage.displayIcon(player.agentID)
					.dynamicallyStroked(radius: 1.5, color: .white)
					.frame(width: iconSize, height: iconSize)
					.mask(Circle())
					.background(Circle().fill(relativeColor).opacity(0.5).padding(2))
					.padding(2)
					.overlay(Circle().strokeBorder(relativeColor, lineWidth: 2))
				
				VStack(alignment: .leading, spacing: 4) {
					if !player.identity.isIncognito, let playerUser = playerUser {
						HStack {
							Text(playerUser.gameName)
							Text("#\(playerUser.tagLine)")
								.foregroundColor(.secondary)
						}
					}
					
					let agentName = assets?.agents[player.agentID]?.displayName
					Text(agentName ?? "Unknown Agent!")
						.fontWeight(.semibold)
				}
				.frame(maxWidth: .infinity, alignment: .leading)
				
				if !isSelf, let playerUser = playerUser {
					NavigationLink(destination: MatchListView(user: playerUser)) {
						Image(systemName: "person.crop.circle.fill")
							.padding(.horizontal, 4)
					}
				}
				
				RankInfoView(summary: summary)
					.frame(width: iconSize, height: iconSize)
			}
			.accentColor(relativeColor)
			.withLocalData($playerUser) { $0.user(for: player.id) }
			.withLocalData($summary) { $0.competitiveSummary(for: player.id) }
			.valorantLoadTask {
				try await LocalDataProvider.shared.fetchCompetitiveSummary(for: player.id, using: $0)
			}
		}
	}
}

#if DEBUG
struct LiveMatchView_Previews: PreviewProvider {
	static var previews: some View {
		LiveMatchContainer(
			matchID: PreviewData.liveGameInfo.id,
			user: PreviewData.user,
			gameInfo: PreviewData.liveGameInfo
		)
		.withToolbar()
	}
}
#endif
