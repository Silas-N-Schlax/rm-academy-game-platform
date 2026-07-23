import { Controller } from "@hotwired/stimulus"

const MELD_MIN_CARDS = 3
const DISCARD_EXACT_CARDS = 1

// Connects to data-controller="game-board"
export default class extends Controller {
  static targets = [
    "tab", "panel", "feedDrawer", "feedScrim", "handCheckbox", "meldAction", "meldDrawIcon",
    "discardAction", "discardDrawIcon", "layoffActionField", "layoffMeldIndexField"
  ]
  static values = { awaitingDraw: Boolean }

  connect() {
    this.syncSelectionState()
    this.morphListener = () => this.syncSelectionState()
    document.addEventListener("turbo:morph", this.morphListener)
  }

  disconnect() {
    document.removeEventListener("turbo:morph", this.morphListener)
  }

  syncSelectionState() {
    const checkedCount = this.handCheckboxTargets.filter((checkbox) => checkbox.checked).length
    this.handCheckboxTargets.forEach((checkbox) => this.syncCardActiveClass(checkbox))
    if (this.hasMeldActionTarget) this.meldActionTarget.disabled = this.awaitingDrawValue || checkedCount < MELD_MIN_CARDS
    if (this.hasDiscardActionTarget) this.discardActionTarget.disabled = this.awaitingDrawValue || checkedCount !== DISCARD_EXACT_CARDS
    if (this.hasMeldDrawIconTarget) this.meldDrawIconTarget.hidden = !this.awaitingDrawValue
    if (this.hasDiscardDrawIconTarget) this.discardDrawIconTarget.hidden = !this.awaitingDrawValue
  }

  syncCardActiveClass(checkbox) {
    const card = checkbox.closest(".game-board__hand-card").querySelector(".playing-card")
    card.classList.toggle("playing-card--active", checkbox.checked)
  }

  clearSelection() {
    this.handCheckboxTargets.forEach((checkbox) => { checkbox.checked = false })
    this.syncSelectionState()
  }

  layOff(event) {
    this.layoffActionFieldTarget.name = "turn[action]"
    this.layoffActionFieldTarget.value = "layoff"
    this.layoffMeldIndexFieldTarget.name = "turn[meld_index]"
    this.layoffMeldIndexFieldTarget.value = event.currentTarget.dataset.meldIndex
    document.getElementById("hand-actions-form").requestSubmit()
  }

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
