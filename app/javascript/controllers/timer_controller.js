import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="timer"
export default class extends Controller {
  static targets = ["time"]

  connect() {
    this.timerController = setInterval(() => {
      if (this.timerInterval == null) {
        this.timeTarget.textContent = '00:00'
        this.startTimer()
      }
    })
  }

  disconnect() {
    clearInterval(this.timerController)
  }

  startTimer() {
    const timeLengthInSeconds = 5
    let remainingTime = timeLengthInSeconds * 100
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
    })
  }

  updateScreen(remainingTime) {
    let seconds = Math.ceil(remainingTime / 100)
    const milliseconds = remainingTime
    const formattedSeconds = String(seconds).padStart(2, '0');
    const formattedMilliseconds = String(milliseconds).padStart(2, '0');
    this.timeTarget.textContent = `${formattedSeconds}:${formattedMilliseconds}`
  }
}
