import type { PropsWithChildren } from 'react'
import type { ScreenId } from '../flows/navigationFlow'

interface IPhoneCanvasProps extends PropsWithChildren {
  screenId: ScreenId
  isActive: boolean
}

export function IPhoneCanvas({ screenId, isActive, children }: IPhoneCanvasProps) {
  return (
    <div className={`phone-frame ${isActive ? 'is-active' : ''}`} data-screen-id={screenId}>
      <div className="dynamic-island" />
      <div className="status-bar"><span>16:03</span><span>•••• ◉ ▰</span></div>
      <div className="phone-content">{children}</div>
      <div className="home-indicator" />
    </div>
  )
}
