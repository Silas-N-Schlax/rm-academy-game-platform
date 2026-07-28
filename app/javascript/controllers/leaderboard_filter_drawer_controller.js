import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="leaderboard-filter-drawer"
export default class extends Controller {
  static targets = ["drawer", "scrim"]

  open() {
    this.drawerTarget.classList.add("is-open")
    this.scrimTarget.classList.add("is-open")
  }

  close() {
    this.drawerTarget.classList.remove("is-open")
    this.scrimTarget.classList.remove("is-open")
  }
}
