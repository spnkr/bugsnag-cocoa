Feature: Signals are captured as error reports in Bugsnag

  Background:
    Given I clear all persistent data

  Scenario: Triggering SIGABRT
    When I run "AbortScenario" and relaunch the app
    And I configure Bugsnag for "AbortScenario"
    And I wait to receive a request
    Then the request is valid for the error reporting API version "4.0" for the "iOS Bugsnag Notifier" notifier
    And the payload field "events" is an array with 1 elements
    And the exception "errorClass" equals "SIGABRT"
    And the "method" of stack frame 0 equals "__pthread_kill"
    And the "method" of stack frame 1 matches "^(<redacted>| ?pthread_kill)$"
    And the "method" of stack frame 2 equals "abort"
    And the "method" of stack frame 3 equals "-[AbortScenario run]"
    And the event "severity" equals "error"
    And the event "unhandled" is true
    And the event "severityReason.type" equals "signal"
    And the event "severityReason.attributes.signalType" equals "SIGABRT"

  Scenario: Triggering SIGABRT with unhandled override
    When I run "AbortScenarioOverride" and relaunch the app
    And I configure Bugsnag for "AbortScenarioOverride"
    And I wait to receive a request
    Then the request is valid for the error reporting API version "4.0" for the "iOS Bugsnag Notifier" notifier
    And the payload field "events" is an array with 1 elements
    And the exception "errorClass" equals "SIGABRT"
    And the "method" of stack frame 0 equals "__pthread_kill"
    And the "method" of stack frame 1 matches "^(<redacted>| ?pthread_kill)$"
    And the "method" of stack frame 2 equals "abort"
    And the "method" of stack frame 3 equals "-[AbortScenarioOverride run]"
    And the event "severity" equals "error"
    And the event "unhandled" is false
    And the event "unhandledOverridden" is true
    And the event "severityReason.type" equals "signal"
    And the event "severityReason.attributes.signalType" equals "SIGABRT"

  Scenario: Triggering SIGPIPE
    When I run "SIGPIPEScenario" and relaunch the app
    And I configure Bugsnag for "SIGPIPEScenario"
    And I wait to receive a request
    Then the request is valid for the error reporting API version "4.0" for the "iOS Bugsnag Notifier" notifier
    And the payload field "events" is an array with 1 elements
    And the exception "errorClass" equals "SIGPIPE"
    And the event "severity" equals "error"
    And the event "unhandled" is true
    And the event "severityReason.type" equals "signal"
    And the event "severityReason.attributes.signalType" equals "SIGPIPE"

  Scenario: Triggering SIGBUS
    When I run "SIGBUSScenario" and relaunch the app
    And I configure Bugsnag for "SIGBUSScenario"
    And I wait to receive a request
    Then the request is valid for the error reporting API version "4.0" for the "iOS Bugsnag Notifier" notifier
    And the payload field "events" is an array with 1 elements
    And the exception "errorClass" equals "SIGBUS"
    And the event "severity" equals "error"
    And the event "unhandled" is true
    And the event "severityReason.type" equals "signal"
    And the event "severityReason.attributes.signalType" equals "SIGBUS"

  Scenario: Triggering SIGFPE
    When I run "SIGFPEScenario" and relaunch the app
    And I configure Bugsnag for "SIGFPEScenario"
    And I wait to receive a request
    Then the request is valid for the error reporting API version "4.0" for the "iOS Bugsnag Notifier" notifier
    And the payload field "events" is an array with 1 elements
    And the exception "errorClass" equals "SIGFPE"
    And the event "severity" equals "error"
    And the event "unhandled" is true
    And the event "severityReason.type" equals "signal"
    And the event "severityReason.attributes.signalType" equals "SIGFPE"

  Scenario: Triggering SIGILL
    When I run "SIGILLScenario" and relaunch the app
    And I configure Bugsnag for "SIGILLScenario"
    And I wait to receive a request
    Then the request is valid for the error reporting API version "4.0" for the "iOS Bugsnag Notifier" notifier
    And the payload field "events" is an array with 1 elements
    And the exception "errorClass" equals "SIGILL"
    And the event "severity" equals "error"
    And the event "unhandled" is true
    And the event "severityReason.type" equals "signal"
    And the event "severityReason.attributes.signalType" equals "SIGILL"

  Scenario: Triggering SIGSEGV
    When I run "SIGSEGVScenario" and relaunch the app
    And I configure Bugsnag for "SIGSEGVScenario"
    And I wait to receive a request
    Then the request is valid for the error reporting API version "4.0" for the "iOS Bugsnag Notifier" notifier
    And the payload field "events" is an array with 1 elements
    And the exception "errorClass" equals "SIGSEGV"
    And the event "severity" equals "error"
    And the event "unhandled" is true
    And the event "severityReason.type" equals "signal"
    And the event "severityReason.attributes.signalType" equals "SIGSEGV"

  Scenario: Triggering SIGSYS
    When I run "SIGSYSScenario" and relaunch the app
    And I configure Bugsnag for "SIGSYSScenario"
    And I wait to receive a request
    Then the request is valid for the error reporting API version "4.0" for the "iOS Bugsnag Notifier" notifier
    And the payload field "events" is an array with 1 elements
    And the exception "errorClass" equals "SIGSYS"
    And the event "severity" equals "error"
    And the event "unhandled" is true
    And the event "severityReason.type" equals "signal"
    And the event "severityReason.attributes.signalType" equals "SIGSYS"

  Scenario: Triggering SIGTRAP
    When I run "SIGTRAPScenario" and relaunch the app
    And I configure Bugsnag for "SIGTRAPScenario"
    And I wait to receive a request
    Then the request is valid for the error reporting API version "4.0" for the "iOS Bugsnag Notifier" notifier
    And the payload field "events" is an array with 1 elements
    And the exception "errorClass" equals "SIGTRAP"
    And the event "severity" equals "error"
    And the event "unhandled" is true
    And the event "severityReason.type" equals "signal"
    And the event "severityReason.attributes.signalType" equals "SIGTRAP"
