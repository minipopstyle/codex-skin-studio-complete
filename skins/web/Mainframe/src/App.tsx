import { useEffect, useRef, useState } from 'react'

const VIDEO_URL = new URL('../theme/background.mp4', import.meta.url).href
const SENSITIVITY = 0.8
const TITLE = 'Make ChatGPT Great Again'
const SUBTITLE = "It's time to crown the new king, Tibo."

function useTypewriter(text: string, speed = 38, startDelay = 600) {
  const [displayed, setDisplayed] = useState('')
  const [done, setDone] = useState(false)

  useEffect(() => {
    let index = 0
    let interval: number | undefined
    const delay = window.setTimeout(() => {
      interval = window.setInterval(() => {
        index += 1
        setDisplayed(text.slice(0, index))
        if (index >= text.length) {
          window.clearInterval(interval)
          setDone(true)
        }
      }, speed)
    }, startDelay)

    return () => {
      window.clearTimeout(delay)
      if (interval) window.clearInterval(interval)
    }
  }, [speed, startDelay, text])

  return { displayed, done }
}

function App() {
  const videoRef = useRef<HTMLVideoElement>(null)
  const prevX = useRef<number | null>(null)
  const targetTime = useRef(0)
  const seeking = useRef(false)
  const [composerOpen, setComposerOpen] = useState(false)
  const { displayed, done } = useTypewriter(TITLE)
  const { displayed: subtitleDisplayed, done: subtitleDone } = useTypewriter(SUBTITLE, 38, done ? 180 : 100000)

  useEffect(() => {
    const video = videoRef.current
    if (!video) return

    const seekNext = () => {
      seeking.current = false
      if (Math.abs(video.currentTime - targetTime.current) > 0.01) {
        seeking.current = true
        video.currentTime = targetTime.current
      }
    }
    const onMouseMove = (event: MouseEvent) => {
      if (!Number.isFinite(video.duration) || video.duration <= 0) return
      const previous = prevX.current ?? event.clientX
      prevX.current = event.clientX
      targetTime.current = Math.max(0, Math.min(video.duration, targetTime.current + ((event.clientX - previous) / window.innerWidth) * SENSITIVITY * video.duration))
      if (!seeking.current) {
        seeking.current = true
        video.currentTime = targetTime.current
      }
    }

    window.addEventListener('mousemove', onMouseMove)
    video.addEventListener('seeked', seekNext)
    return () => {
      window.removeEventListener('mousemove', onMouseMove)
      video.removeEventListener('seeked', seekNext)
    }
  }, [])

  return (
    <main id="top" className="relative min-h-screen overflow-hidden bg-[#d9ff33] text-black">
      <video
        ref={videoRef}
        className="fixed inset-0 z-0 h-full w-full object-cover object-[70%_center]"
        src={VIDEO_URL}
        muted
        playsInline
        preload="auto"
        aria-hidden="true"
      />
      <section className="relative z-[2] flex h-screen flex-col justify-end overflow-hidden px-5 pb-12 sm:px-8 sm:pb-14 md:justify-center md:px-10 md:pb-0">
        <div className="relative z-10 max-w-xl">
          <p className="pointer-events-none mb-5 origin-left scale-x-[.72] select-none whitespace-pre-line text-[clamp(18px,4vw,26px)] font-normal leading-[1.3] text-black blur-[4px] sm:mb-6">
            {"Hey there, meet A.R.I.A,\nMainframe's Adaptive Response Interface Agent"}
          </p>
          <p className="mb-2 min-h-0 text-[clamp(18px,4vw,26px)] font-normal leading-[1.35]">
            {displayed}
            {!done && <span className="ml-[2px] inline-block h-[1.1em] w-[2px] animate-blink bg-black align-middle" />}
          </p>
          <p className="mb-5 text-[clamp(15px,2.5vw,18px)] font-normal leading-[1.3] text-black sm:mb-6">
            {subtitleDisplayed}
            {!subtitleDone && <span className="ml-[2px] inline-block h-[1.1em] w-[2px] animate-blink bg-black align-middle" />}
          </p>
          <button type="button" disabled={!subtitleDone} onClick={() => setComposerOpen((open) => !open)} aria-expanded={composerOpen} className={`rounded-full border border-white/80 bg-white/40 px-5 py-2.5 text-sm shadow-[0_12px_30px_rgb(0_0_0_/_0.12),inset_0_1px_0_rgb(255_255_255_/_0.9),inset_0_-1px_0_rgb(0_0_0_/_0.08)] backdrop-blur-lg transition hover:-translate-y-0.5 active:scale-95 ${subtitleDone ? 'translate-y-0 opacity-100' : 'pointer-events-none translate-y-2 opacity-0'}`}>
            {composerOpen ? 'Until Tomorrow' : 'Here We Go'}
          </button>
        </div>
      </section>

      {composerOpen && (
        <div className="fixed bottom-24 right-5 z-10 flex w-[min(520px,calc(100vw-40px))] items-end gap-2 rounded-2xl border border-black/15 bg-white/90 p-3 shadow-2xl backdrop-blur sm:right-8">
          <textarea autoFocus rows={2} placeholder="Start a new task..." className="min-h-12 flex-1 resize-none bg-transparent px-2 py-1 text-sm outline-none placeholder:text-black/50" />
          <button type="button" onClick={() => setComposerOpen(false)} className="grid h-9 w-9 shrink-0 place-items-center rounded-full bg-black text-white" aria-label="Close composer">×</button>
        </div>
      )}
    </main>
  )
}

export default App
