import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="card-select"
export default class extends Controller {
  static targets = [ "card", "rankField", "suitField" ]

  connect() {
    this.syncSelectionState()
    this.morphListener = () => this.syncSelectionState()
    document.addEventListener("turbo:morph", this.morphListener)
  }

  disconnect() {
    document.removeEventListener("turbo:morph", this.morphListener)
  }

  choose(event) {
    this.rankFieldTarget.value = event.target.dataset.rank
    if (this.hasSuitFieldTarget) this.suitFieldTarget.value = event.target.dataset.suit
    this.syncSelectionState()
  }

  syncSelectionState() {
    const selected = this.cardTargets.find((card) => card.checked)
    this.cardTargets.forEach((card) => this.syncCardActiveClass(card, selected))
    this.element.classList.toggle("is-armed", !!selected)
  }

  syncCardActiveClass(card, selected) {
    const image = card.closest(".game-hand__card").querySelector(".playing-card")
    image.classList.toggle("playing-card--active", card === selected)
  }
}
