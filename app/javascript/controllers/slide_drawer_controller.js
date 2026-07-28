import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="slide-drawer"
export default class extends Controller {
  static targets = ["panel", "scrim"]

  open() {
    this.panelTarget.classList.add("is-open")
    this.scrimTarget.classList.add("is-open")
  }

  close() {
    this.panelTarget.classList.remove("is-open")
    this.scrimTarget.classList.remove("is-open")
  }
}
