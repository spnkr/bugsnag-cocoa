When("I run {string}") do |event_type|
  steps %Q{
    Given the element "scenario_name" is present
    When I send the keys "#{event_type}" to the element "scenario_name"
    And I close the keyboard
    And I click the element "run_scenario"
  }
end

When("I set the app to {string} mode") do |mode|
  steps %Q{
    Given the element "scenario_metadata" is present
    When I send the keys "#{mode}" to the element "scenario_metadata"
    And I close the keyboard
  }
end

When("I run {string} and relaunch the app") do |event_type|
  steps %Q{
    When I run "#{event_type}"
    And I relaunch the app
  }
end

When("I clear all persistent data") do
  steps %Q{
    Given the element "clear_persistent_data" is present
    And I click the element "clear_persistent_data"
  }
end

When("I close the keyboard") do
  case MazeRunner.driver.capabilities["platformName"]
  when 'Mac'
    # There is no software keyboard to hide
  else
    steps %Q{
      Given the element "close_keyboard" is present
      And I click the element "close_keyboard"
    }
  end
end

When("I configure Bugsnag for {string}") do |event_type|
  steps %Q{
    Given the element "scenario_name" is present
    When I send the keys "#{event_type}" to the element "scenario_name"
    And I close the keyboard
    And I click the element "start_bugsnag"
  }
end

When("I send the app to the background") do
  MazeRunner.driver.background_app(-1)
end

When("I relaunch the app") do
  # FIXME: this logic belongs in maze-runner, but I cannot see how to override launch_app
  case MazeRunner.driver.capabilities["platformName"]
  when 'Mac'
    app = MazeRunner.driver.capabilities["app"]
    system("killall #{app} > /dev/null && sleep 1")
    MazeRunner.driver.get(app)
  else
    MazeRunner.driver.launch_app
  end
end

When("I clear the request queue") do
  Server.stored_requests.clear
end

When("derp {string}") do |value|
  send_keys_to_element("scenario_name", value)
end

# 0: The current application state cannot be determined/is unknown
# 1: The application is not running
# 2: The application is running in the background and is suspended
# 3: The application is running in the background and is not suspended
# 4: The application is running in the foreground
Then("The app is running in the foreground") do
  wait_for_true do
    status = MazeRunner.driver.execute_script('mobile: queryAppState', {bundleId: "com.bugsnag.iOSTestApp"})
    status == 4
  end
end

Then("The app is running in the background") do
  wait_for_true do
    status = MazeRunner.driver.execute_script('mobile: queryAppState', {bundleId: "com.bugsnag.iOSTestApp"})
    status == 3
  end
end

Then("The app is not running") do
  wait_for_true do
    status = MazeRunner.driver.execute_script('mobile: queryAppState', {bundleId: "com.bugsnag.iOSTestApp"})
    status == 1
  end
end

Then("the received requests match:") do |table|
  # Checks that each request matches one of the event fields
  requests = Server.stored_requests
  request_count = requests.count()
  match_count = 0

  # iterate through each row in the table. exactly 1 request should match each row.
  table.hashes.each do |row|
    requests.each do |request|
      if !request.key? :body or !request[:body].key? "events" then
        # No body.events in this request - skip
        return
      end
      events = request[:body]['events']
      assert_equal(1, events.length, 'Expected exactly one event per request')
      match_count += 1 if request_matches_row(events[0], row)
    end
  end
  assert_equal(request_count, match_count, "Unexpected number of requests matched the received payloads")
end

def request_matches_row(body, row)
  row.each do |key, expected_value|
    obs_val = read_key_path(body, key)
    next if ("null".eql? expected_value) && obs_val.nil? # Both are null/nil
    next if !obs_val.nil? && (expected_value.to_s.eql? obs_val.to_s) # Values match
    # Match not found - return false
    return false
  end
  # All matched - return true
  true
end

Then("the payload field {string} is equal for request {int} and request {int}") do |key, index_a, index_b|
  assert_true(request_fields_are_equal(key, index_a, index_b))
end

Then("the payload field {string} is not equal for request {int} and request {int}") do |key, index_a, index_b|
  assert_false(request_fields_are_equal(key, index_a, index_b))
end

def request_fields_are_equal(key, index_a, index_b)
  requests = Server.stored_requests.to_a
  assert_true(requests.length > index_a, "Not enough requests received to access index #{index_a}")
  assert_true(requests.length > index_b, "Not enough requests received to access index #{index_b}")
  request_a = requests[index_a][:body]
  request_b = requests[index_b][:body]
  val_a = read_key_path(request_a, key)
  val_b = read_key_path(request_b, key)
  val_a.eql? val_b
end

Then("the event {string} equals one of:") do |field, possible_values|
  value = read_key_path(Server.current_request[:body], "events.0.#{field}")
  assert_includes(possible_values.raw.flatten, value)
end

Then("the event {string} is within {int} seconds of the current timestamp") do |field, threshold_secs|
  value = read_key_path(Server.current_request[:body], "events.0.#{field}")
  assert_not_nil(value, "Expected a timestamp")
  now_secs = Time.now.to_i
  then_secs = Time.parse(value).to_i
  delta = now_secs - then_secs
  assert_true(delta.abs < threshold_secs, "Expected current timestamp, but received #{value}")
end

Then("the event breadcrumbs contain {string} with type {string}") do |string, type|
  crumbs = read_key_path(find_request(0)[:body], "events.0.breadcrumbs")
  assert_not_equal(0, crumbs.length, "There are no breadcrumbs on this event")
  match = crumbs.detect do |crumb|
    crumb["name"] == string && crumb["type"] == type
  end
  assert_not_nil(match, "No crumb matches the provided message and type")
end

Then("the event breadcrumbs contain {string}") do |string|
  crumbs = read_key_path(Server.current_request[:body], "events.0.breadcrumbs")
  assert_not_equal(0, crumbs.length, "There are no breadcrumbs on this event")
  match = crumbs.detect do |crumb|
    crumb["name"] == string
  end
  assert_not_nil(match, "No crumb matches the provided message")
end

Then("the stack trace is an array with {int} stack frames") do |expected_length|
  stack_trace = read_key_path(Server.current_request[:body], "events.0.exceptions.0.stacktrace")
  assert_equal(expected_length, stack_trace.length)
end

Then("the {string} of stack frame {int} equals one of:") do |key, num, possible_values|
  field = "events.0.exceptions.0.stacktrace.#{num}.#{key}"
  value = read_key_path(Server.current_request[:body], field)
  assert_includes(possible_values.raw.flatten, value)
end

Then("the stacktrace contains methods:") do |table|
  stack_trace = read_key_path(Server.current_request[:body], "events.0.exceptions.0.stacktrace")
  expected = table.raw.flatten
  actual = stack_trace.map { |s| s["method"] }
  contains = actual.each_cons(expected.length).to_a.include? expected
  assert_true(contains, "Stacktrace methods #{actual} did not contain #{expected}")
end

Then("the payload field {string} equals one of:") do |field, possible_values|
  value = read_key_path(Server.current_request[:body], field)
  assert_includes(possible_values.raw.flatten, value)
end

Then("the payload field {string} matches the test device model") do |field|
  internal_names = {
      "iPhone 7" => %w[iPhone9,1 iPhone9,2 iPhone9,3 iPhone9,4],
      "iPhone 8" => %w[iPhone10,1 iPhone10,2 iPhone10,4 iPhone10,5],
      "iPhone 11" => %w[iPhone12,1],
      "iPhone 11 Pro" => %w[iPhone12,3],
      "iPhone 11 Pro Max" => %w[iPhone12,5],
      "iPhone X" => %w[iPhone10,3 iPhone10,6],
      "iPhone XR" => ["iPhone11,8"],
      "iPhone XS" => %w[iPhone11,2 iPhone11,4 iPhone11,8]
  }
  expected_model = MazeRunner.config.capabilities["device"]
  valid_models = internal_names[expected_model]
  device_model = read_key_path(Server.current_request[:body], field)
  assert_true(valid_models != nil ? valid_models.include?(device_model) : true, "The field #{device_model} did not match any of the list of expected fields")
end

Then("the thread information is valid for the event") do
  # veriy that thread/stacktrace information was captured at all
  thread_traces = read_key_path(Server.current_request[:body], "events.0.threads")
  stack_traces = read_key_path(Server.current_request[:body], "events.0.exceptions.0.stacktrace")
  assert_not_nil(thread_traces, "No thread trace recorded")
  assert_not_nil(stack_traces, "No thread trace recorded")
  assert_true(stack_traces.count() > 0, "Expected stacktrace collected to be > 0.")
  assert_true(thread_traces.count() > 0, "Expected number of threads collected to be > 0.")

  # verify threads are recorded and contain plausible information (id, type, stacktrace)
  thread_traces.each do |thread|
    assert_not_nil(thread["id"], "Thread ID missing for #{thread}")
    assert_equal("cocoa", thread["type"], "Thread type does not equal 'cocoa' for #{thread}")
    stacktrace = thread["stacktrace"]
    assert_not_nil(stacktrace, "Stacktrace is null for #{thread}")
    stack_traces.each do |frame|
      assert_not_nil(frame["method"], "Method is null for frame #{frame}")
    end
  end

  # verify the errorReportingThread is present and set for only oine thread
  err_thread_count = 0
  err_thread_trace = nil
  thread_traces.each.with_index do |thread, index|
    if thread["errorReportingThread"] == true
      err_thread_count += 1
      err_thread_trace = thread["stacktrace"]
    end
  end
  assert_equal(1, err_thread_count, "Expected errorReportingThread to be reported once for threads #{thread_traces}")

  # verify the errorReportingThread stacktrace matches the exception stacktrace
  stack_traces.each_with_index do |frame, index|
    thread_frame = err_thread_trace[index]
    assert_equal(frame, thread_frame, "Thread and stacktrace differ at #{index}. Stack=#{frame}, thread=#{thread_frame}")
  end
end

Then("the request is valid for the error reporting API") do
  case MazeRunner.driver.capabilities["platformName"]
  when 'iOS'
    steps %Q{
      Then the request is valid for the error reporting API version "4.0" for the "iOS Bugsnag Notifier" notifier
    }
  when 'Mac'
    steps %Q{
      Then the request is valid for the error reporting API version "4.0" for the "iOS Bugsnag Notifier" notifier
    }
  else
    raise "Unknown platformName"
  end
end

Then("the request is valid for the session reporting API") do
  case MazeRunner.driver.capabilities["platformName"]
  when 'iOS'
    steps %Q{
      Then the request is valid for the session reporting API version "1.0" for the "iOS Bugsnag Notifier" notifier
    }
  when 'Mac'
    steps %Q{
      Then the request is valid for the session reporting API version "1.0" for the "iOS Bugsnag Notifier" notifier
    }
  else
    raise "Unknown platformName"
  end
end

Then("the exception {string} equals one of:") do |keypath, possible_values|
  value = read_key_path(Server.current_request[:body], "events.0.exceptions.0.#{keypath}")
  assert_includes(possible_values.raw.flatten, value)
end

Then("the error is an OOM event") do
  steps %Q{
    Then the exception "message" equals "The app was likely terminated by the operating system while in the foreground"
    And the exception "errorClass" equals "Out Of Memory"
    And the exception "type" equals "cocoa"
    And the payload field "events.0.exceptions.0.stacktrace" is an array with 0 elements
    And the event "severity" equals "error"
    And the event "severityReason.type" equals "outOfMemory"
    And the event "unhandled" is true
  }
end

def wait_for_true
  max_attempts = 300
  attempts = 0
  assertion_passed = false
  until (attempts >= max_attempts) || assertion_passed
    attempts += 1
    assertion_passed = yield
    sleep 0.1
  end
  raise "Assertion not passed in 30s" unless assertion_passed
end

def send_keys_to_element(element_id, text)
  element = find_element(@element_locator, element_id)
  element.clear()
  element.set_value(text)
end
