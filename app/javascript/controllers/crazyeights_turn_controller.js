import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="crazyeights-turn"
export default class extends Controller {
  static targets = [ "wildSuitField" ]
  static values = { wildRank: String }

  play() {
    if (!this.element.classList.contains("is-armed")) return

    if (this.selectedRank() === this.wildRankValue) {
      document.getElementById("wild-dialog").showModal()
      return
    }

    document.getElementById("play-form").requestSubmit()
  }

  chooseSuit(event) {
    this.wildSuitFieldTarget.value = event.currentTarget.dataset.suit
    document.getElementById("wild-dialog").close()
    document.getElementById("play-form").requestSubmit()
  }

  selectedRank() {
    return this.element.querySelector("[data-card-select-target='rankField']").value
  }
}
