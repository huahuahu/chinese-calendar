const dayNames = [
  '初一', '初二', '初三', '初四', '初五', '初六', '初七', '初八', '初九', '初十',
  '十一', '十二', '十三', '十四', '十五', '十六', '十七', '十八', '十九', '二十',
  '廿一', '廿二', '廿三', '廿四', '廿五', '廿六', '廿七', '廿八', '廿九', '三十',
]

const dayStems = [
  '乙丑', '丙寅', '丁卯', '戊辰', '己巳', '庚午', '辛未', '壬申', '癸酉', '甲戌',
  '乙亥', '丙子', '丁丑', '戊寅', '己卯', '庚辰', '辛巳', '壬午', '癸未', '甲申',
  '乙酉', '丙戌', '丁亥', '戊子', '己丑', '庚寅', '辛卯', '壬辰', '癸巳', '甲午',
]

export const lunarDays = dayNames.map((name, index) => {
  const civilDay = index === 0 ? '10/31' : `11/${index}`
  return [name, dayStems[index], civilDay] as const
})

export const years = [2030, 2031, 2032, 2033, 2034, 2035, 2036, 2037, 2038, 2039, 2040, 2041]

export const stems = ['庚戌', '辛亥', '壬子', '癸丑', '甲寅', '乙卯', '丙辰', '丁巳', '戊午', '己未', '庚申', '辛酉']

export function stemBranchForYear(year: number) {
  return stems[years.indexOf(year)] ?? '乙卯'
}
