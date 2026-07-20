import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="timer"
export default class extends Controller {
  static targets = ["time"]
  static values = { timerTime: { type: Number, default: 30 } }

  connect() {
    this.timerController = setInterval(() => {
      if (this.timerInterval == null) {
        this.timeTarget.textContent = '00'
        this.startTimer()
      }
    })
  }

  disconnect() {
    clearInterval(this.timerController)
  }

  startTimer() {
    console.log(this.timerTimeValue)
    if (this.timerTimeValue == undefined) return
    let remainingTime = this.timerTimeValue
    this.timerInterval = null

    this.timerInterval = setInterval(() => {
      if (remainingTime > 0) {
        remainingTime--
        this.updateScreen(remainingTime)
      } else {
        clearInterval(this.timerInterval)
        this.timerInterval = null
        this.dispatch('timer-over', {
          details: { autoPlay: true }
        })
      }
    }, 1000)
  }

  updateScreen(remainingTime) {
    const formattedSeconds = String(remainingTime).padStart(2, '0');
    this.timeTarget.textContent = formattedSeconds
  }
}
