import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="service-worker"
export default class extends Controller {
  static values = { url: String }

  connect() {
    if ('serviceWorker' in navigator) {
      console.log('hello')
      navigator.serviceWorker.register(this.urlValue)
    }
  }
}
