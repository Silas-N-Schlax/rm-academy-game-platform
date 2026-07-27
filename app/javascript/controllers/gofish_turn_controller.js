import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="gofish-turn"
export default class extends Controller {
  static targets = [ "playerField" ]

  target(event) {
    if (!this.element.classList.contains("is-armed")) return

    event.preventDefault()
    this.playerFieldTarget.value = event.currentTarget.dataset.playerId
    document.getElementById("ask-form").requestSubmit()
  }
}
