import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="game-board-feed"
export default class extends Controller {
  static targets = ["feedDrawer", "feedScrim"]

  openFeed() {
    this.feedDrawerTarget.classList.add("is-open")
    this.feedScrimTarget.classList.add("is-open")
  }

  closeFeed() {
    this.feedDrawerTarget.classList.remove("is-open")
    this.feedScrimTarget.classList.remove("is-open")
  }
}
