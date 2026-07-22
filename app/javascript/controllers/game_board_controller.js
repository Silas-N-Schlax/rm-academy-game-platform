import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="game-board"
export default class extends Controller {
  static targets = ["tab", "panel", "feedDrawer", "feedScrim"]

  switchTab(event) {
    const tab = event.currentTarget.dataset.tab
    this.tabTargets.forEach((t) => t.classList.toggle("btn--active", t === event.currentTarget))
    this.panelTargets.forEach((p) => p.classList.toggle("game-board__panel--active", p.dataset.panel === tab))
  }

  openFeed() {
    this.feedDrawerTarget.classList.add("is-open")
    this.feedScrimTarget.classList.add("is-open")
  }

  closeFeed() {
    this.feedDrawerTarget.classList.remove("is-open")
    this.feedScrimTarget.classList.remove("is-open")
  }
}
