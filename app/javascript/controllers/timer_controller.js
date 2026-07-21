import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="timer"
export default class extends Controller {
  static targets = ["time"]
  static values = { seconds: Number, anchor: Number }

  anchorValueChanged() {
    this.restart()
  }

  disconnect() {
    clearInterval(this.timerInterval)
  }

  restart() {
    clearInterval(this.timerInterval)
    this.startTime = Date.now()
    this.initialRemaining = this.secondsValue
    this.fired = false
    this.updateScreen(this.initialRemaining)
    this.timerInterval = setInterval(() => this.tick(), 1000)
  }

  tick() {
    const elapsed = Math.floor((Date.now() - this.startTime) / 1000)
    const remaining = Math.max(this.initialRemaining - elapsed, 0)
    this.updateScreen(remaining)
    if (remaining <= 0) this.fireTimerOver()
  }

  fireTimerOver() {
    clearInterval(this.timerInterval)
    if (this.fired) return
    this.fired = true
    this.dispatch('timer-over', { detail: { autoPlay: true } })
  }

  updateScreen(remainingTime) {
    const formattedSeconds = String(Math.ceil(remainingTime)).padStart(2, '0');
    this.timeTarget.textContent = formattedSeconds
  }
}
