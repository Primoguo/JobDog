import Foundation

// MARK: - 场景变体静态数据

enum SceneData {

    /// 回退变体（数据为空时使用）
    static let fallbackVariant = SceneVariant(
        id: "FALLBACK",
        timeSlot: .morning,
        layout: SceneLayout(
            location: "家",
            furniture: [],
            floorColor: "D4B896",
            wallColor: "E8D8C0",
            gridSize: .init(width: 8, height: 6)
        ),
        dogAction: "待在家里",
        interactiveProps: [],
        attributeEffects: [:],
        weatherCondition: nil
    )

    /// 所有变体
    static let allVariants: [SceneVariant] = {
        var all: [SceneVariant] = []
        all.append(contentsOf: officeVariants)
        all.append(contentsOf: freeVariants)
        all.append(contentsOf: disciplinedVariants)
        return all
    }()

    /// 按条件筛选变体
    static func variants(for mode: LifeMode, timeSlot: TimeSlot, weather: Weather) -> [SceneVariant] {
        let pool: [SceneVariant]
        switch mode {
        case .office: pool = officeVariants
        case .free: pool = freeVariants
        case .disciplined: pool = disciplinedVariants
        }
        return pool.filter { variant in
            variant.timeSlot == timeSlot &&
            (variant.weatherCondition == nil || variant.weatherCondition == weather)
        }
    }

    // MARK: - 上班族变体（首批）

    static let officeVariants: [SceneVariant] = [
        // 清晨
        SceneVariant(
            id: "O-EM-1",
            timeSlot: .earlyMorning,
            layout: SceneLayout(
                location: "卧室",
                furniture: [
                    FurnitureItem(id: "bed", name: "床", emoji: "🛏️", position: .init(x: 1, y: 1), size: .init(width: 2, height: 3), color: "B8A088"),
                    FurnitureItem(id: "alarm", name: "闹钟", emoji: "⏰", position: .init(x: 3, y: 1), size: .init(width: 1, height: 1), color: "C8C8C8")
                ],
                floorColor: "D4B896",
                wallColor: "E8D8C0",
                gridSize: .init(width: 6, height: 5)
            ),
            dogAction: "被闹钟吵醒，揉着眼睛",
            interactiveProps: [
                InteractiveProp(id: "snooze", type: .rest, emoji: "⏰", position: .init(x: 3, y: 1), effect: ["energy": 5, "mood": -2], cost: 0, label: "再睡5分钟")
            ],
            attributeEffects: ["energy": -1, "mood": -1],
            weatherCondition: nil
        ),
        // 上午
        SceneVariant(
            id: "O-M-1",
            timeSlot: .morning,
            layout: SceneLayout(
                location: "办公室",
                furniture: [
                    FurnitureItem(id: "desk", name: "办公桌", emoji: "🖥️", position: .init(x: 2, y: 2), size: .init(width: 2, height: 1), color: "A08870"),
                    FurnitureItem(id: "chair", name: "办公椅", emoji: "🪑", position: .init(x: 2, y: 3), size: .init(width: 1, height: 1), color: "606060"),
                    FurnitureItem(id: "plant", name: "绿植", emoji: "🪴", position: .init(x: 5, y: 1), size: .init(width: 1, height: 1), color: "7C9B64")
                ],
                floorColor: "C8D8C8",
                wallColor: "E8E8E8",
                gridSize: .init(width: 7, height: 5)
            ),
            dogAction: "认真打字，处理邮件",
            interactiveProps: [
                InteractiveProp(id: "coffee", type: .drink, emoji: "☕", position: .init(x: 4, y: 2), effect: ["energy": 8, "mood": 3], cost: 15, label: "喝杯咖啡")
            ],
            attributeEffects: ["mood": -1, "energy": -3, "fullness": -2],
            weatherCondition: nil
        ),
        // 中午
        SceneVariant(
            id: "O-N-1",
            timeSlot: .noon,
            layout: SceneLayout(
                location: "公司食堂",
                furniture: [
                    FurnitureItem(id: "table", name: "餐桌", emoji: "🍽️", position: .init(x: 2, y: 2), size: .init(width: 2, height: 1), color: "C8A880"),
                    FurnitureItem(id: "tray", name: "餐盘", emoji: "🍱", position: .init(x: 2, y: 2), size: .init(width: 1, height: 1), color: "E8E0D0")
                ],
                floorColor: "D0D0D0",
                wallColor: "F0E8D8",
                gridSize: .init(width: 6, height: 5)
            ),
            dogAction: "排队打饭，找了个靠窗位置",
            interactiveProps: [
                InteractiveProp(id: "lunch", type: .feed, emoji: "🍱", position: .init(x: 2, y: 2), effect: ["fullness": 25, "mood": 5], cost: 20, label: "吃午饭")
            ],
            attributeEffects: ["fullness": 10, "mood": 2, "energy": 3],
            weatherCondition: nil
        ),
        // 下午
        SceneVariant(
            id: "O-A-1",
            timeSlot: .afternoon,
            layout: SceneLayout(
                location: "会议室",
                furniture: [
                    FurnitureItem(id: "confTable", name: "会议桌", emoji: "📋", position: .init(x: 2, y: 2), size: .init(width: 3, height: 2), color: "8B7355"),
                    FurnitureItem(id: "projector", name: "投影仪", emoji: "📽️", position: .init(x: 5, y: 0), size: .init(width: 1, height: 1), color: "404040")
                ],
                floorColor: "C8D8C8",
                wallColor: "E8E8E8",
                gridSize: .init(width: 7, height: 5)
            ),
            dogAction: "开会中，认真做笔记",
            interactiveProps: [
                InteractiveProp(id: "water", type: .drink, emoji: "💧", position: .init(x: 5, y: 2), effect: ["fullness": 3], cost: 0, label: "喝口水")
            ],
            attributeEffects: ["mood": -2, "energy": -4, "fullness": -2],
            weatherCondition: nil
        ),
        // 傍晚
        SceneVariant(
            id: "O-E-1",
            timeSlot: .evening,
            layout: SceneLayout(
                location: "回家路上",
                furniture: [
                    FurnitureItem(id: "train", name: "地铁", emoji: "🚇", position: .init(x: 1, y: 2), size: .init(width: 4, height: 2), color: "4080C0"),
                    FurnitureItem(id: "phone", name: "手机", emoji: "📱", position: .init(x: 5, y: 3), size: .init(width: 1, height: 1), color: "303030")
                ],
                floorColor: "A0A0A0",
                wallColor: nil,
                gridSize: .init(width: 7, height: 5)
            ),
            dogAction: "挤地铁回家，刷着手机",
            interactiveProps: [
                InteractiveProp(id: "music", type: .play, emoji: "🎵", position: .init(x: 5, y: 3), effect: ["mood": 5], cost: 0, label: "听音乐")
            ],
            attributeEffects: ["energy": -2, "mood": 1],
            weatherCondition: nil
        ),
    ]

    // MARK: - 自由人变体（首批）

    static let freeVariants: [SceneVariant] = [
        // 上午晚
        SceneVariant(
            id: "F-LM-1",
            timeSlot: .lateMorning,
            layout: SceneLayout(
                location: "家中书房",
                furniture: [
                    FurnitureItem(id: "laptop", name: "笔记本电脑", emoji: "💻", position: .init(x: 2, y: 2), size: .init(width: 2, height: 1), color: "C0C0C0"),
                    FurnitureItem(id: "bookshelf", name: "书架", emoji: "📚", position: .init(x: 5, y: 0), size: .init(width: 1, height: 3), color: "8B6B4A"),
                    FurnitureItem(id: "cat", name: "猫", emoji: "🐱", position: .init(x: 0, y: 4), size: .init(width: 1, height: 1), color: "E8C8A0")
                ],
                floorColor: "D4B896",
                wallColor: "E8D8C0",
                gridSize: .init(width: 7, height: 5)
            ),
            dogAction: "在书房接了一个新项目",
            interactiveProps: [
                InteractiveProp(id: "tea", type: .drink, emoji: "🍵", position: .init(x: 4, y: 2), effect: ["mood": 3, "energy": 2], cost: 0, label: "泡杯茶")
            ],
            attributeEffects: ["mood": 2, "energy": -1],
            weatherCondition: nil
        ),
        // 中午
        SceneVariant(
            id: "F-N-1",
            timeSlot: .noon,
            layout: SceneLayout(
                location: "街边小店",
                furniture: [
                    FurnitureItem(id: "counter", name: "柜台", emoji: "🏪", position: .init(x: 0, y: 1), size: .init(width: 1, height: 3), color: "C8A060"),
                    FurnitureItem(id: "stool", name: "凳子", emoji: "🪑", position: .init(x: 3, y: 3), size: .init(width: 1, height: 1), color: "A08060")
                ],
                floorColor: "C0B0A0",
                wallColor: nil,
                gridSize: .init(width: 6, height: 5)
            ),
            dogAction: "在街边小店吃午饭",
            interactiveProps: [
                InteractiveProp(id: "noodles", type: .feed, emoji: "🍜", position: .init(x: 1, y: 2), effect: ["fullness": 20, "mood": 3], cost: 15, label: "来碗面")
            ],
            attributeEffects: ["fullness": 8, "mood": 2],
            weatherCondition: nil
        ),
        // 下午晚
        SceneVariant(
            id: "F-LA-1",
            timeSlot: .lateAfternoon,
            layout: SceneLayout(
                location: "公园",
                furniture: [
                    FurnitureItem(id: "bench", name: "长椅", emoji: "🪑", position: .init(x: 2, y: 3), size: .init(width: 2, height: 1), color: "8B6B4A"),
                    FurnitureItem(id: "tree", name: "大树", emoji: "🌳", position: .init(x: 5, y: 1), size: .init(width: 2, height: 2), color: "5D8B6A"),
                    FurnitureItem(id: "fountain", name: "喷泉", emoji: "⛲", position: .init(x: 0, y: 0), size: .init(width: 2, height: 2), color: "80B0D0")
                ],
                floorColor: "8CB87C",
                wallColor: nil,
                gridSize: .init(width: 8, height: 6)
            ),
            dogAction: "在公园散步放松",
            interactiveProps: [
                InteractiveProp(id: "frisbee", type: .play, emoji: "🥏", position: .init(x: 4, y: 4), effect: ["mood": 8, "energy": -5], cost: 0, label: "扔飞盘")
            ],
            attributeEffects: ["mood": 3, "energy": -2, "cleanliness": -2],
            weatherCondition: nil
        ),
        // 傍晚
        SceneVariant(
            id: "F-E-1",
            timeSlot: .evening,
            layout: SceneLayout(
                location: "厨房",
                furniture: [
                    FurnitureItem(id: "stove", name: "灶台", emoji: "🍳", position: .init(x: 1, y: 1), size: .init(width: 2, height: 1), color: "404040"),
                    FurnitureItem(id: "fridge", name: "冰箱", emoji: "🧊", position: .init(x: 5, y: 0), size: .init(width: 1, height: 2), color: "E0E0E0"),
                    FurnitureItem(id: "table2", name: "餐桌", emoji: "🍽️", position: .init(x: 3, y: 3), size: .init(width: 2, height: 1), color: "C8A880")
                ],
                floorColor: "D4B896",
                wallColor: "F0E8D8",
                gridSize: .init(width: 7, height: 5)
            ),
            dogAction: "在厨房做晚饭",
            interactiveProps: [
                InteractiveProp(id: "cook", type: .feed, emoji: "🍳", position: .init(x: 1, y: 1), effect: ["fullness": 25, "mood": 5], cost: 10, label: "做饭吃")
            ],
            attributeEffects: ["mood": 3, "fullness": 5],
            weatherCondition: nil
        ),
        // 夜晚
        SceneVariant(
            id: "F-NI-1",
            timeSlot: .night,
            layout: SceneLayout(
                location: "客厅",
                furniture: [
                    FurnitureItem(id: "sofa", name: "沙发", emoji: "🛋️", position: .init(x: 1, y: 2), size: .init(width: 3, height: 2), color: "8B7355"),
                    FurnitureItem(id: "tv", name: "电视", emoji: "📺", position: .init(x: 5, y: 0), size: .init(width: 2, height: 1), color: "202020"),
                    FurnitureItem(id: "lamp", name: "台灯", emoji: "💡", position: .init(x: 0, y: 0), size: .init(width: 1, height: 1), color: "FFE0A0")
                ],
                floorColor: "D4B896",
                wallColor: "E8D8C0",
                gridSize: .init(width: 8, height: 5)
            ),
            dogAction: "窝在沙发上看电视",
            interactiveProps: [
                InteractiveProp(id: "snack", type: .feed, emoji: "🍿", position: .init(x: 4, y: 3), effect: ["fullness": 5, "mood": 3], cost: 10, label: "吃零食")
            ],
            attributeEffects: ["mood": 3, "energy": -1],
            weatherCondition: nil
        ),
    ]

    // MARK: - 自律者变体（首批）

    static let disciplinedVariants: [SceneVariant] = [
        // 清晨
        SceneVariant(
            id: "D-EM-1",
            timeSlot: .earlyMorning,
            layout: SceneLayout(
                location: "公园跑道",
                furniture: [
                    FurnitureItem(id: "path", name: "跑道", emoji: "🏃", position: .init(x: 1, y: 2), size: .init(width: 6, height: 1), color: "C8A080"),
                    FurnitureItem(id: "tree2", name: "树", emoji: "🌲", position: .init(x: 0, y: 0), size: .init(width: 1, height: 2), color: "4A7A4A"),
                    FurnitureItem(id: "tree3", name: "树", emoji: "🌲", position: .init(x: 7, y: 0), size: .init(width: 1, height: 2), color: "4A7A4A")
                ],
                floorColor: "8CB87C",
                wallColor: nil,
                gridSize: .init(width: 8, height: 5)
            ),
            dogAction: "晨跑中，呼吸均匀",
            interactiveProps: [
                InteractiveProp(id: "water2", type: .drink, emoji: "💧", position: .init(x: 6, y: 3), effect: ["fullness": 3, "energy": 2], cost: 0, label: "喝口水")
            ],
            attributeEffects: ["energy": -3, "mood": 5, "cleanliness": -3],
            weatherCondition: nil
        ),
        // 上午
        SceneVariant(
            id: "D-M-1",
            timeSlot: .morning,
            layout: SceneLayout(
                location: "图书馆",
                furniture: [
                    FurnitureItem(id: "desk2", name: "书桌", emoji: "📖", position: .init(x: 2, y: 2), size: .init(width: 2, height: 1), color: "A08870"),
                    FurnitureItem(id: "bookshelf2", name: "书架", emoji: "📚", position: .init(x: 0, y: 0), size: .init(width: 1, height: 4), color: "8B6B4A"),
                    FurnitureItem(id: "bookshelf3", name: "书架", emoji: "📚", position: .init(x: 6, y: 0), size: .init(width: 1, height: 4), color: "8B6B4A")
                ],
                floorColor: "D4B896",
                wallColor: "E8E0D0",
                gridSize: .init(width: 7, height: 5)
            ),
            dogAction: "在图书馆专注学习",
            interactiveProps: [
                InteractiveProp(id: "notebook", type: .work, emoji: "📝", position: .init(x: 4, y: 2), effect: ["mood": 2], cost: 0, label: "做笔记")
            ],
            attributeEffects: ["mood": -1, "energy": -4, "fullness": -2],
            weatherCondition: nil
        ),
        // 中午
        SceneVariant(
            id: "D-N-1",
            timeSlot: .noon,
            layout: SceneLayout(
                location: "健身房",
                furniture: [
                    FurnitureItem(id: "treadmill", name: "跑步机", emoji: "🏋️", position: .init(x: 1, y: 1), size: .init(width: 2, height: 2), color: "404040"),
                    FurnitureItem(id: "mat", name: "瑜伽垫", emoji: "🧘", position: .init(x: 4, y: 2), size: .init(width: 2, height: 1), color: "8080C0"),
                    FurnitureItem(id: "mirror", name: "镜子", emoji: "🪞", position: .init(x: 6, y: 0), size: .init(width: 1, height: 3), color: "C0D0E0")
                ],
                floorColor: "C0C0C0",
                wallColor: "E0E0E0",
                gridSize: .init(width: 8, height: 5)
            ),
            dogAction: "午间健身，挥汗如雨",
            interactiveProps: [
                InteractiveProp(id: "protein", type: .drink, emoji: "🥤", position: .init(x: 6, y: 3), effect: ["fullness": 10, "energy": 5], cost: 20, label: "蛋白粉")
            ],
            attributeEffects: ["energy": -5, "mood": 3, "cleanliness": -5],
            weatherCondition: nil
        ),
        // 下午
        SceneVariant(
            id: "D-A-1",
            timeSlot: .afternoon,
            layout: SceneLayout(
                location: "工作室",
                furniture: [
                    FurnitureItem(id: "desk3", name: "工作台", emoji: "💻", position: .init(x: 2, y: 2), size: .init(width: 3, height: 1), color: "606060"),
                    FurnitureItem(id: "whiteboard", name: "白板", emoji: "📊", position: .init(x: 5, y: 0), size: .init(width: 2, height: 1), color: "F0F0F0"),
                    FurnitureItem(id: "plant2", name: "绿植", emoji: "🪴", position: .init(x: 0, y: 0), size: .init(width: 1, height: 1), color: "7C9B64")
                ],
                floorColor: "D4B896",
                wallColor: "F0F0F0",
                gridSize: .init(width: 8, height: 5)
            ),
            dogAction: "在工作室专注写代码",
            interactiveProps: [
                InteractiveProp(id: "coffee2", type: .drink, emoji: "☕", position: .init(x: 5, y: 2), effect: ["energy": 5, "mood": 2], cost: 15, label: "喝咖啡")
            ],
            attributeEffects: ["mood": -1, "energy": -4, "fullness": -2],
            weatherCondition: nil
        ),
        // 夜晚
        SceneVariant(
            id: "D-NI-1",
            timeSlot: .night,
            layout: SceneLayout(
                location: "浴室",
                furniture: [
                    FurnitureItem(id: "bathtub", name: "浴缸", emoji: "🛁", position: .init(x: 1, y: 1), size: .init(width: 3, height: 2), color: "E0E8F0"),
                    FurnitureItem(id: "mirror2", name: "镜子", emoji: "🪞", position: .init(x: 5, y: 0), size: .init(width: 2, height: 1), color: "C0D0E0")
                ],
                floorColor: "D0D8E0",
                wallColor: "E8E8F0",
                gridSize: .init(width: 8, height: 5)
            ),
            dogAction: "泡澡放松，准备入睡",
            interactiveProps: [
                InteractiveProp(id: "bath", type: .clean, emoji: "🧼", position: .init(x: 1, y: 1), effect: ["cleanliness": 30, "mood": 5], cost: 0, label: "泡澡")
            ],
            attributeEffects: ["cleanliness": 10, "mood": 3, "energy": 2],
            weatherCondition: nil
        ),
    ]
}
