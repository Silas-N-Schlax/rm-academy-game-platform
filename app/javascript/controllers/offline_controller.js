import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="offline"
export default class extends Controller {
  static targets = [ "offlineBanner" ]

  connect() {
    this.updateStatus()

    this.boundUpdateStatus = this.updateStatus.bind(this)

    window.addEventListener('online', this.boundUpdateStatus)
    window.addEventListener('offline', this.boundUpdateStatus)
  }

  disconnect() {
    window.removeEventListener('online', this.boundUpdateStatus)
    window.removeEventListener('offline', this.boundUpdateStatus)
  }

  updateStatus() {
    if (navigator.onLine) {
      this.offlineBannerTarget.classList.remove('offline-banner--active')

    } else {
      this.offlineBannerTarget.classList.add('offline-banner--active')
    }
  }
}
