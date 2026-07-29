import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="range-slider"
export default class extends Controller {
  static targets = ["minInput", "maxInput", "minHidden", "maxHidden", "output"]

  updateMin() {
    const min = Math.min(Number(this.minInputTarget.value), Number(this.maxInputTarget.value) - 1)
    this.minInputTarget.value = min
    this.minHiddenTarget.value = min
    this.render()
  }

  updateMax() {
    const max = Math.max(Number(this.maxInputTarget.value), Number(this.minInputTarget.value) + 1)
    this.maxInputTarget.value = max
    this.maxHiddenTarget.value = max
    this.render()
  }

  render() {
    this.outputTarget.textContent = `${this.minInputTarget.value}–${this.maxInputTarget.value}`
  }
}
