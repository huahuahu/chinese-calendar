# 干支与生肖循环结论

本文记录对上游 `ytliu0/ChineseCalendar`、当前导入脚本和已生成数据的核对结果，主要回答三个问题：

- 年、月、日干支是否一直循环，是否存在突变。
- 生肖在当前数据中是事实字段，还是由地支派生。
- 历史特殊年份会不会影响数据库建模。

## 数据来源

当前原始数据固定在上游仓库：

```text
https://github.com/ytliu0/ChineseCalendar
commit: d6aae82b63b79a6f8659ea3e064024b7d8ac3077
```

本地导入范围见 `Data/Processed/swiftdata_import/manifest.json`：

- civil year：`-220...2200`
- calendar days：`884256`
- Chinese lunar years：`2421`
- Chinese lunar months：`29944`

说明：代码和数据使用天文年号，`0` 表示公元前 1 年，`-103` 表示公元前 104 年。

## 结论总览

| 层级 | 是否连续循环 | 结论 |
|---|---|---|
| 年干支 | 是 | 数据范围内没有突变，每年天干 `+1 mod 10`、地支 `+1 mod 12`。 |
| 月干支 | 普通月是 | 非闰月连续推进；闰月复用前一个月干支，不推进。 |
| 日干支 | 是 | 按儒略日数连续推进，civil date 的跳日不影响日干支。 |
| 生肖 | 由年地支派生 | 不是上游逐年事实字段，而是 `animal[yearBranchIndex]`。 |

## 生肖逻辑

上游在 `calendar.js` 中定义固定的十二生肖表：

| branchIndex | 地支 | 生肖 |
|---:|---|---|
| 0 | 子 | 鼠 |
| 1 | 丑 | 牛 |
| 2 | 寅 | 虎 |
| 3 | 卯 | 兔 |
| 4 | 辰 | 龙 |
| 5 | 巳 | 蛇 |
| 6 | 午 | 马 |
| 7 | 未 | 羊 |
| 8 | 申 | 猴 |
| 9 | 酉 | 鸡 |
| 10 | 戌 | 狗 |
| 11 | 亥 | 猪 |

当前导入数据不保存单独的 `zodiac` 字段。生肖应由 `ChineseLunarYear.yearBranchIndex` 派生。

例如：

```text
2024 -> branchIndex 4 -> 龙
2025 -> branchIndex 5 -> 蛇
2026 -> branchIndex 6 -> 马
```

历史语义上，地支系统早于生肖属相体系。对很早的年份，直接显示“属龙、属蛇”等属于用后世稳定生肖体系解释年地支。若 UI 需要历史严谨，可以在早期年份显示为“按后世生肖对应为龙”，或只显示干支。

## 年干支

导入脚本中的年干支公式：

```javascript
yearStemIndex = positiveModulo(lunarYearNumber + 726, 10)
yearBranchIndex = positiveModulo(lunarYearNumber + 728, 12)
```

扫过 `-220...2200` 的 `2421` 个农历年：

- 年号连续。
- 年干每年 `+1 mod 10`。
- 年支每年 `+1 mod 12`。
- 没有发现突变。

因此年干支可以视为稳定连续的六十甲子循环。

## 月干支

月干支按上游的“月建”计算，导入脚本保存为：

```javascript
monthBranchIndex = positiveModulo(jian + 1, 12)
```

月干也由年干相关偏移和月建共同计算。

对 `29944` 个农历月的扫描结果：

- 非闰月之间没有发现干支突变。
- 发现 `892` 次“没有推进一格”的情况。
- 这些情况全部发生在闰月附近。

这说明月干支的规则不是“每个实际农历月都推进一格”，而是：

- 普通月推进。
- 闰月复用被闰的那个月的干支。

例如普通九月为某个干支时，闰九月仍为同一个干支，下一个普通月才继续推进。

历史改正朔会影响月名和年界，但不代表月干支随机突变。例如公元前 104 年对应数据中的 `lunarYearNumber = -103`，这个农历年有 15 个月，月名为：

```text
十月、十一月、十二月、正月、二月、三月、四月、五月、六月、七月、八月、九月、十月、十一月、十二月
```

但它们的月干支仍按月建顺序推进：

```text
己亥、庚子、辛丑、壬寅、癸卯、甲辰、乙巳、丙午、丁未、戊申、己酉、庚戌、辛亥、壬子、癸丑
```

## 日干支

日干支按儒略日数计算，导入脚本中的公式：

```javascript
dayStemIndex = positiveModulo(julianDayNumber - 1, 10)
dayBranchIndex = positiveModulo(julianDayNumber + 1, 12)
```

扫过当前全部 `884256` 天：

- `dayIndex` 连续。
- `julianDayNumber` 连续。
- 日干每天 `+1 mod 10`。
- 日支每天 `+1 mod 12`。
- 没有发现突变。

1582 年 Gregorian reform 是一个重要例子。civil date 从 `1582-10-04 Julian` 跳到 `1582-10-15 Gregorian`，但 absolute day 没有跳，因此日干支继续推进。

| civil date | 日干 index | 日支 index |
|---|---:|---:|
| 1582-10-03 Julian | 8 | 8 |
| 1582-10-04 Julian | 9 | 9 |
| 1582-10-15 Gregorian | 0 | 10 |
| 1582-10-16 Gregorian | 1 | 11 |

## 历史特殊年与数据库建模

历史改正朔会让同一个农历年出现重复月名，甚至出现 10、11、14、15 个月的年份。这会影响唯一键设计。

当前 `ChineseLunarMonth` 如果使用以下复合唯一键，会与真实数据冲突：

```swift
[\.lunarYearNumber, \.monthNumberInYear, \.isLeapMonth]
```

已生成数据中至少有这些重复组合：

| lunarYearNumber | 月 | isLeapMonth | 说明 |
|---:|---:|---|---|
| -103 | 10 | false | 公元前 104 年过渡年，两个十月。 |
| -103 | 11 | false | 两个十一月。 |
| -103 | 12 | false | 两个十二月。 |
| 23 | 12 | false | 两个十二月。 |
| 239 | 12 | false | 两个十二月。 |
| 700 | 11 | false | 两个十一月。 |
| 700 | 12 | false | 两个十二月。 |
| 762 | 4 | false | 两个四月。 |
| 762 | 5 | false | 两个五月。 |

因此 `ChineseLunarMonth` 的稳定身份应优先使用全局 `lunarMonthIndex`。如果需要年内唯一定位，还应加入年内实际顺序、月起始日或其他能区分重复同名月的字段，而不能只用“农历年 + 月号 + 是否闰月”。

