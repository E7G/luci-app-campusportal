local http = luci.http

m = Map("campusportal", translate("Campus Portal Settings"),
    translate("Configure campus network portal authentication parameters. "
        .. "This service monitors network connectivity and automatically re-authenticates "
        .. "when the captive portal is detected."))

s = m:section(TypedSection, "campusportal")
s.addremove = false
s.anonymous = true

enable = s:option(Flag, "enabled", translate("Enable"))
enable.rmempty = false
enable.default = 0

username = s:option(Value, "username", translate("Username"))
username.rmempty = false

password = s:option(Value, "password", translate("Password"))
password.password = true
password.rmempty = false

service = s:option(Value, "service", translate("Service"),
    translate("Service field (usually left empty)"))

interface = s:option(Value, "interface", translate("Network Interface"),
    translate("Network interface for Macvlan multi-account, e.g. eth1"))
interface.rmempty = false
interface.default = "eth1"

captive_url = s:option(Value, "captive_url", translate("Captive Portal URL"),
    translate("URL that returns HTTP 204 when authenticated, used for connectivity detection"))
captive_url.rmempty = false
captive_url.default = "http://www.google.cn/generate_204"

monitor_interval = s:option(Value, "monitor_interval", translate("Monitor Interval (seconds)"))
monitor_interval.datatype = "range(10,3600)"
monitor_interval.default = 60

retry_max = s:option(Value, "retry_max", translate("Max Retries"))
retry_max.datatype = "range(1,10)"
retry_max.default = 3

retry_sleep = s:option(Value, "retry_sleep", translate("Retry Interval (seconds)"))
retry_sleep.datatype = "range(1,30)"
retry_sleep.default = 2

user_agent = s:option(Value, "user_agent", translate("User-Agent"),
    translate("HTTP User-Agent header used for requests"))

return m