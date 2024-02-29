local cjson = require "cjson"
local basic_serializer = require "kong.plugins.log-serializers.basic"



local kong = kong
local ngx = ngx
local timer_at = ngx.timer.at


local function log(premature, conf, message)
  if premature then
    return
  end

  local host = conf.host
  local port = conf.port
  local timeout = conf.timeout
  local keepalive = conf.keepalive

  local sock = ngx.socket.tcp()
  sock:settimeout(timeout)

  local ok, err = sock:connect(host, port)
  if not ok then
    kong.log.err("failed to connect to ", host, ":", tostring(port), ": ", err)
    return
  end

  if conf.tls then
    ok, err = sock:sslhandshake(true, conf.tls_sni, false)
    if not ok then
      kong.log.err("failed to perform TLS handshake to ", host, ":", port, ": ", err)
      return
    end
  end

  ok, err = sock:send(cjson.encode(message) .. "\n")
  if not ok then
    kong.log.err("failed to send data to ", host, ":", tostring(port), ": ", err)
  end

  ok, err = sock:setkeepalive(keepalive)
  if not ok then
    kong.log.err("failed to keepalive to ", host, ":", tostring(port), ": ", err)
    return
  end
end


local TcpLogHandler = {
  PRIORITY = 7,
  VERSION = "2.0.1",
}



function TcpLogHandler:access(conf)
    local ctx = kong.ctx.plugin;
    ctx.request_body = kong.request.get_raw_body();
end


function TcpLogHandler:body_filter(conf)
  local ctx = kong.ctx.plugin;
  local chunk, eof = ngx.arg[1], ngx.arg[2];
  if not eof then
     ctx.response_body = (ctx.response_body or "") .. (chunk or "")
  end
end

function TcpLogHandler:log(conf)
  local ctx = kong.ctx.plugin;
  local log_obj = basic_serializer.serialize(ngx)
  log_obj.request.body = ctx.request_body
  log_obj.response.body = ctx.response_body


  local ok, err = timer_at(0, log, conf, log_obj)
  if not ok then
    kong.log.err("failed to create timer: ", err)
  end
end


return TcpLogHandler
