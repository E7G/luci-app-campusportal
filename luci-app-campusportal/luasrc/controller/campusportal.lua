module("luci.controller.campusportal", package.seeall)

function index()
    if not nixio.fs.access("/etc/config/campusportal") then
        return
    end

    entry({"admin", "services", "campusportal"}, firstchild(), _("Campus Portal"), 60).dependent = true
    entry({"admin", "services", "campusportal", "status"}, cbi("campusportal_status"), _("Status"), 1).leaf = true
    entry({"admin", "services", "campusportal", "config"}, cbi("campusportal"), _("Settings"), 2).leaf = true
    entry({"admin", "services", "campusportal", "log"}, template("campusportal/campusportal_log"), _("Logs"), 3).leaf = true
    entry({"admin", "services", "campusportal", "api_status"}, call("act_status")).leaf = true
    entry({"admin", "services", "campusportal", "api_login"}, call("act_login")).leaf = true
    entry({"admin", "services", "campusportal", "get_log"}, call("get_log")).leaf = true
    entry({"admin", "services", "campusportal", "clear_log"}, call("clear_log")).leaf = true
end

function act_status()
    local e = {}
    local uci = require "luci.model.uci".cursor()

    e.enabled = uci:get_first("campusportal", "campusportal", "enabled") == "1"
    e.running = luci.sys.call("pgrep -f 'campusportal' | grep -v 'pgrep' >/dev/null 2>&1 && pgrep -f '/etc/init.d/campusportal' | grep -v 'pgrep' >/dev/null 2>&1") == 0

    local online_check = luci.sys.exec("export $(uci show campusportal.@campusportal[0] 2>/dev/null | awk -F'=' '{gsub(/\\047/,\"\"); print $1\"=\"$2}' | tr '\\n' ' '); curl -s -I -m 10 -o /dev/null -w '%{http_code}' --interface \"$interface\" \"$captive_url\" 2>/dev/null")
    e.online = (online_check:match("204") ~= nil)

    local interface = uci:get_first("campusportal", "campusportal", "interface") or "eth1"
    e.interface = interface

    local uptime_file = "/tmp/campusportal_uptime"
    local f = io.open(uptime_file, "r")
    if f then
        local start_time = tonumber(f:read("*all"))
        f:close()
        if start_time then
            local elapsed = os.time() - start_time
            local days = math.floor(elapsed / 86400)
            local hours = math.floor((elapsed % 86400) / 3600)
            local mins = math.floor((elapsed % 3600) / 60)
            local secs = elapsed % 60
            local result = ""
            if days > 0 then result = days .. "d " end
            e.uptime = result .. string.format("%02d:%02d:%02d", hours, mins, secs)
        end
    end
    if not e.uptime then
        e.uptime = "-"
    end

    luci.http.prepare_content("application/json")
    luci.http.write_json(e)
end

function act_login()
    luci.http.prepare_content("application/json")

    local handle = io.popen("/etc/init.d/campusportal login 2>&1")
    if not handle then
        luci.http.write_json({success = false, message = "Failed to execute login command"})
        return
    end
    local output = handle:read("*all") or ""
    handle:close()

    local success = output:match("Login success") ~= nil
    local message = output:gsub("[\r\n]+", " | ")

    luci.http.write_json({
        success = success,
        message = message
    })
end

function get_log()
    local log = ""
    local log_file = "/tmp/campusportal.log"
    if luci.sys.call("[ -f '" .. log_file .. "' ]") == 0 then
        log = luci.sys.exec("cat " .. log_file)
    end
    luci.http.write(log)
end

function clear_log()
    luci.sys.call("echo '' >/tmp/campusportal.log 2>/dev/null")
    luci.http.prepare_content("application/json")
    luci.http.write_json({success = true})
end