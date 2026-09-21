export function HistoryTabBar() {
  return (
    <nav className="floating-tab-bar history-tab-bar" aria-label="主标签页">
      <button type="button"><span aria-hidden="true">▦</span>日历</button>
      <button type="button" className="is-selected"><span aria-hidden="true">◫</span>朝代</button>
      <button type="button"><span aria-hidden="true">⚙</span>设置</button>
    </nav>
  )
}
