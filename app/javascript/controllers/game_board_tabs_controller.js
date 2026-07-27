import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="game-board-tabs"
export default class extends Controller {
  static targets = ["tab", "panel"]

  switchTab(event) {
    const tab = event.currentTarget.dataset.tab
    this.tabTargets.forEach((t) => t.classList.toggle("tab--active", t === event.currentTarget))
    this.panelTargets.forEach((p) => p.classList.toggle("game-board__panel--active", p.dataset.panel === tab))
  }
}
