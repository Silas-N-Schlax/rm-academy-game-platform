import { Controller } from "@hotwired/stimulus"

const DISMISS_AFTER_MS = 4000

// Connects to data-controller="game-board-toast"
export default class extends Controller {
  static targets = ["description"]
  static values = { message: String }

  messageValueChanged() {
    clearTimeout(this.dismissTimeout)
    if (!this.messageValue) return this.element.classList.remove("alert-banner--active")
    this.descriptionTarget.textContent = this.messageValue
    this.element.classList.add("alert-banner--active")
    this.dismissTimeout = setTimeout(() => this.close(), DISMISS_AFTER_MS)
  }

  close() {
    clearTimeout(this.dismissTimeout)
    this.element.classList.remove("alert-banner--active")
  }
}
