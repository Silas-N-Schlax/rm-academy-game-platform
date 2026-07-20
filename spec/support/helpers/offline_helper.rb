module OfflineHelper
  def emulate_worker_network(offline:)
    network = page.driver.browser.devtools(target_type: 'service_worker').network
    network.enable
    network.emulate_network_conditions(offline: offline, latency: 0, download_throughput: -1, upload_throughput: -1)
  end

  def wait_for_service_worker_control
    Timeout.timeout(Capybara.default_max_wait_time) do
      sleep 0.1 until page.evaluate_script('navigator.serviceWorker.controller != null')
    end
  end
end
