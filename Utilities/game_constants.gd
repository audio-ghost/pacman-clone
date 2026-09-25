class_name GameConstants

const GROUP_PLAYER = "Player"
const GROUP_GHOSTS = "Ghosts"

enum GameState {
	GET_READY,
	PLAYING,
	LEVEL_COMPLETE,
	GAME_OVER
}

enum GhostMode {
	SCATTER,
	CHASE
}

enum Personality {
	CHASER,
	AMBUSHER,
	RANDOM,
	PATROL,
	HUNTER,
	STATUE,
	CHAMELEON,
	SCAREDYCAT
}

enum GhostState {
	IN_HOUSE,
	EXITING,
	ACTIVE,
	FRIGHTENED,
	EATEN
}

enum ScatterPoint {
	TOP_LEFT,
	TOP_RIGHT,
	BOTTOM_LEFT,
	BOTTOM_RIGHT
}
