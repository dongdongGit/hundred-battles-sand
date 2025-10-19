#Requires AutoHotkey v2.0

; 野外BOSS坐标配置（一维数组结构）
global WildBossCoordinates := Map(
    "诡异神殿一层", Map(
        "boss_icon", Map("x", 75, "y", 175),
        "challenge_btn", Map("x", 275, "y", 275),
        "list_area", Map("x1", 100, "y1", 350, "x2", 300, "y2", 600),
        "location_area", Map("x1", 350, "y1", 350, "x2", 550, "y2", 600),
        "scroll", Map("direction", "up", "distance", 200)
    ),
    "诡异神殿二层", Map(
        "boss_icon", Map("x", 75, "y", 175),
        "challenge_btn", Map("x", 275, "y", 275),
        "list_area", Map("x1", 100, "y1", 350, "x2", 300, "y2", 600),
        "location_area", Map("x1", 350, "y1", 350, "x2", 550, "y2", 600),
        "scroll", Map("direction", "up", "distance", 220)
    ),
    "诡异神殿三层", Map(
        "boss_icon", Map("x", 75, "y", 175),
        "challenge_btn", Map("x", 275, "y", 275),
        "list_area", Map("x1", 100, "y1", 350, "x2", 300, "y2", 600),
        "location_area", Map("x1", 350, "y1", 350, "x2", 550, "y2", 600),
        "scroll", Map("direction", "up", "distance", 240)
    ),
    "诡异神殿四层", Map(
        "boss_icon", Map("x", 75, "y", 175),
        "challenge_btn", Map("x", 275, "y", 275),
        "list_area", Map("x1", 100, "y1", 350, "x2", 300, "y2", 600),
        "location_area", Map("x1", 350, "y1", 350, "x2", 550, "y2", 600),
        "scroll", Map("direction", "up", "distance", 260)
    )
)

; 获取野外BOSS坐标配置
GetWildBossCoordinates() {
    return WildBossCoordinates
}

; 根据地点名称获取坐标信息
GetWildBossCoordinate(locationName) {
    if (WildBossCoordinates.Has(locationName)) {
        return WildBossCoordinates[locationName]
    }
    return false
}

; 获取所有地点名称
GetWildBossCoordinateLocations() {
    locations := []
    for location in WildBossCoordinates {
        locations.Push(location)
    }
    return locations
}