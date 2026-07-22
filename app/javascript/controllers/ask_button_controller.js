import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="ask-button"
export default class extends Controller {
  static targets = ["player", "rank", "label"]

  connect() {
    this.update()
  }

  update() {
    const player = this.playerTarget.selectedOptions[0].text
    const rank = this.rankTarget.selectedOptions[0].text
    this.labelTarget.value = `Ask ${player} for ${rank}s`
  }
}
