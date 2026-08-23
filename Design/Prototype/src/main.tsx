import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './design-system/tokens.css'
import './design-system/themes.css'
import './styles.css'
import { PrototypeApp } from './prototype/PrototypeApp'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <PrototypeApp />
  </StrictMode>,
)
