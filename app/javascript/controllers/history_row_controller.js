import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="history-row"
export default class extends Controller {
  static values = { dialogId: String }

  open() {
    document.getElementById(this.dialogIdValue).showModal()
  }
}
