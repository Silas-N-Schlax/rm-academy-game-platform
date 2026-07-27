import { Controller } from "@hotwired/stimulus"

const DISMISS_AFTER_MS = 4000

// Connects to data-controller="action-notice"
export default class extends Controller {
  static targets = [ "text" ]
  static values = { message: String }

  messageValueChanged() {
    clearTimeout(this.dismissTimeout)
    if (!this.messageValue) return this.element.classList.remove("action-notice--active")
    this.textTarget.textContent = this.messageValue
    this.element.classList.add("action-notice--active")
    this.dismissTimeout = setTimeout(() => this.close(), DISMISS_AFTER_MS)
  }

  close() {
    clearTimeout(this.dismissTimeout)
    this.element.classList.remove("action-notice--active")
  }
}
