require "test_helper"
require "capybara/selenium/driver"
require "capybara/selenium/driver_specializations/chrome_driver"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]
end

# Workaround for Chrome 158+ rejecting `origin: "*"` in Storage.clearDataForOrigin
# Remove once Capybara releases a patched version
Capybara::Selenium::Driver::ChromeDriver.prepend(
  Module.new do
    def execute_cdp(cmd, params = {}, **kwargs)
      merged = params.merge(kwargs)

      if cmd == "Storage.clearDataForOrigin" && (merged[:origin] == "*" || merged["origin"] == "*")
        origin = Capybara.current_session.server&.base_url || Capybara.app_host
        return super("Network.clearBrowserCookies") unless origin&.start_with?("http")

        merged = merged.merge(origin: origin)
        merged.delete("origin")
      end

      if merged.empty?
        super(cmd)
      elsif merged.keys.all?(Symbol)
        super(cmd, **merged)
      else
        super(cmd, merged)
      end
    end
  end
)
