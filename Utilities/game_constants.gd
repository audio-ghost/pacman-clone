class_name GameConstants


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
