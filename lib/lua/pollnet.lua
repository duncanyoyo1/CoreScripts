--[[ 
pollnet bindings for luajit
example usage to read twitch chat:
local pollnet = require("pollnet")
local async = require("async") -- assuming you have some kind of async
local function await_message(sock)
  while sock:poll() do
    if sock:last_message() then 
      return sock:last_message() 
    end
    -- Important!
    async.await_frames(1) 
  end
  error("Socket closed:", sock:last_message())
end
async.run(function()
  local url = "wss://irc-ws.chat.twitch.tv:443"
  local sock = pollnet.open_ws(url)
  sock:send("PASS doesntmatter")
  -- special nick for anon read-only access on twitch
  local anon_user_name = "justinfan" .. math.random(1, 100000)
  local target_channel = "your_channel_name_here"
  sock:send("NICK " .. anon_user_name)
  sock:send("JOIN #" .. target_channel)
  
  while true do
    local msg = await_message(sock)
    if msg == "PING :tmi.twitch.tv" then
      sock:send("PONG :tmi.twitch.tv")
    else
      print(msg)
    end
  end
end)
-- example http get:
async.run(function()
  local sock = pollnet.http_get("https://www.example.com")
  print("Status:", await_message(sock))
  print("Headers:", await_message(sock))
  print("Body:", await_message(sock))
  sock:close()
end)
]]

local ffi = require("ffi")
ffi.cdef[[
struct pnctx* pollnet_init();
struct pnctx* pollnet_get_or_init_static();
void pollnet_shutdown(struct pnctx* ctx);
unsigned int pollnet_open_tcp(struct pnctx* ctx, const char* addr);
unsigned int pollnet_listen_tcp(struct pnctx* ctx, const char* addr);
unsigned int pollnet_open_ws(struct pnctx* ctx, const char* url);
unsigned int pollnet_simple_http_get(struct pnctx* ctx, const char* url, unsigned int body_only);
unsigned int pollnet_simple_http_post(struct pnctx* ctx, const char* url, unsigned int ret_body_only, const char* content_type, const char* data, unsigned int datasize);
void pollnet_close(struct pnctx* ctx, unsigned int handle);
void pollnet_close_all(struct pnctx* ctx);
void pollnet_send(struct pnctx* ctx, unsigned int handle, const char* msg);
void pollnet_send_binary(struct pnctx* ctx, unsigned int handle, const char* msg, unsigned int msgsize);
unsigned int pollnet_update(struct pnctx* ctx, unsigned int handle);
unsigned int pollnet_update_blocking(struct pnctx* ctx, unsigned int handle);
int pollnet_get(struct pnctx* ctx, unsigned int handle, char* dest, unsigned int dest_size);
int pollnet_get_error(struct pnctx* ctx, unsigned int handle, char* dest, unsigned int dest_size);
unsigned int pollnet_get_connected_client_handle(struct pnctx* ctx, unsigned int handle);
unsigned int pollnet_listen_ws(struct pnctx* ctx, const char* addr);
unsigned int pollnet_serve_static_http(struct pnctx* ctx, const char* addr, const char* serve_dir);
unsigned int pollnet_serve_http(struct pnctx* ctx, const char* addr);
void pollnet_add_virtual_file(struct pnctx* ctx, unsigned int handle, const char* filename, const char* filedata, unsigned int filesize);
void pollnet_remove_virtual_file(struct pnctx* ctx, unsigned int handle, const char* filename);
int pollnet_get_nanoid(char* dest, unsigned int dest_size);
void pollnet_sleep_ms(unsigned int milliseconds);
]]

local POLLNET_RESULT_CODES = {
  [0] = "invalid_handle",
  [1] = "closed",
  [2] = "opening",
  [3] = "nodata",
  [4] = "hasdata",
  [5] = "error",
  [6] = "newclient"
}

local pollnet = ffi.load(config.pathToDlls .. "pollnet")
local _ctx = nil

local function init_ctx()
  if _ctx then return end
  _ctx = ffi.gc(pollnet.pollnet_init(), pollnet.pollnet_shutdown)
  assert(_ctx ~= nil)
end

local function init_ctx_hack_static()
  if _ctx then return end
  _ctx = pollnet.pollnet_get_or_init_static()
  assert(_ctx ~= nil)
  pollnet.pollnet_close_all(_ctx)
end

local function shutdown_ctx()
  if not _ctx then return end
  pollnet.pollnet_shutdown(ffi.gc(_ctx, nil))
  _ctx = nil
end

local socket_mt = {}
local function Socket()
  return setmetatable({}, {__index = socket_mt})
end

function socket_mt:_open(scratch_size, opener, ...)
  init_ctx()
  if self._socket then self:close() end
  scratch_size = scratch_size or 64000
  if type(opener) == "number" then
    self._socket = opener
  else
    self._socket = opener(_ctx, ...)
  end
  self._scratch = ffi.new("int8_t[?]", scratch_size)
  self._scratch_size = scratch_size
  self._status = "unpolled"
  return self
end

local function bool_to_int(b)
  return (b and 1) or 0
end

function socket_mt:http_get(url, ret_body_only, scratch_size)
  return self:_open(
    scratch_size, 
    pollnet.pollnet_simple_http_get, 
    url, 
    bool_to_int(ret_body_only)
  )
end

function socket_mt:http_post(url, ret_body_only, body, content_type, scratch_size)
  body = body or ""
  content_type = content_type or "application/x-www-form-urlencoded"
  return self:_open(
    scratch_size, 
    pollnet.pollnet_simple_http_post, 
    url, 
    bool_to_int(ret_body_only), 
    content_type,
    body, 
    #body
  )
end

function socket_mt:open_ws(url, scratch_size)
  return self:_open(scratch_size, pollnet.pollnet_open_ws, url)
end

function socket_mt:open_tcp(addr, scratch_size)
  return self:_open(scratch_size, pollnet.pollnet_open_tcp, addr)
end

function socket_mt:serve_http(addr, dir, scratch_size)
  self.is_http_server = true
  if dir and dir ~= "" then
    return self:_open(scratch_size, pollnet.pollnet_serve_static_http, addr, dir)
  else
    return self:_open(scratch_size, pollnet.pollnet_serve_http, addr)
  end
end

function socket_mt:add_virtual_file(filename, filedata)
  assert(filedata)
  local dsize = #filedata
  pollnet.pollnet_add_virtual_file(_ctx, self._socket, filename, filedata, dsize)
end

function socket_mt:remove_virtual_file(filename)
  pollnet.pollnet_remove_virtual_file(_ctx, self._socket, filename)
end

function socket_mt:listen_ws(addr, scratch_size)
  return self:_open(scratch_size, pollnet.pollnet_listen_ws, addr)
end

function socket_mt:listen_tcp(addr, scratch_size)
  return self:_open(scratch_size, pollnet.pollnet_listen_tcp, addr)
end

function socket_mt:on_connection(f)
  self._on_connection = f
  return self
end

function socket_mt:_get_message()
  local msg_size = pollnet.pollnet_get(_ctx, self._socket, self._scratch, self._scratch_size)
  if msg_size > 0 then
    return ffi.string(self._scratch, msg_size)
  else
    return nil
  end
end

function socket_mt:poll()
  if not self._socket then 
    self._status = "invalid"
    return false, "invalid"
  end
  local res = POLLNET_RESULT_CODES[pollnet.pollnet_update(_ctx, self._socket)] or "error"
  self._status = res
  self._last_message = nil
  if res == "hasdata" then
    self._status = "open"
    self._last_message = self:_get_message()
    return true, self._last_message
  elseif res == "nodata" then
    self._status = "open"
    return true
  elseif res == "opening" then
    self._status = "opening"
    return true
  elseif res == "error" then
    self._status = "error"
    self._last_message = self:error_msg()
    return false, self._last_message
  elseif res == "closed" then
    self._status = "closed"
    return false, "closed"
  elseif res == "newclient" then
    self._status = "open"
    local client_addr = self:_get_message()
    local client_handle = pollnet.pollnet_get_connected_client_handle(_ctx, self._socket)
    assert(client_handle > 0)
    local client_sock = Socket():_open(self._scratch_size, client_handle)
    client_sock.parent = self
    client_sock.remote_addr = client_addr
    if self._on_connection then
      self._on_connection(client_sock, client_addr)
    else
      print("No connection handler! All incoming connections will be closed!")
      client_sock:close()
    end
    return true
  end
end

function socket_mt:last_message()
  return self._last_message
end
function socket_mt:status()
  return self._status
end
function socket_mt:send(msg)
  assert(self._socket)
  pollnet.pollnet_send(_ctx, self._socket, msg)
end
function socket_mt:close()
  assert(self._socket)
  pollnet.pollnet_close(_ctx, self._socket)
  self._socket = nil
end
function socket_mt:error_msg()
  if not self._socket then return "No socket!" end
  local msg_size = pollnet.pollnet_get_error(_ctx, self._socket, self._scratch, self._scratch_size)
  if msg_size > 0 then
    local smsg = ffi.string(self._scratch, msg_size)
    return smsg
  else
    return nil
  end
end

local function open_ws(url, scratch_size)
  return Socket():open_ws(url, scratch_size)
end

local function listen_ws(addr, scratch_size)
  return Socket():listen_ws(addr, scratch_size)
end

local function open_tcp(addr, scratch_size)
  return Socket():open_tcp(addr, scratch_size)
end

local function listen_tcp(addr, scratch_size)
  return Socket():listen_tcp(addr, scratch_size)
end

local function serve_http(addr, dir, scratch_size)
  return Socket():serve_http(addr, dir, scratch_size)
end

local function http_get(url, return_body_only, scratch_size)
  return Socket():http_get(url, return_body_only, scratch_size)
end

local function http_post(url, return_body_only, body, content_type, scratch_size)
  return Socket():http_post(url, return_body_only, body, content_type, scratch_size)
end

local function get_nanoid()
  local _id_scratch = ffi.new("int8_t[?]", 128)
  local msg_size = pollnet.pollnet_get_nanoid(_id_scratch, 128)
  return ffi.string(_id_scratch, msg_size)
end

local function sleep_ms(ms)
  pollnet.pollnet_sleep_ms(ms)
end

return {
  init = init_ctx,
  init_hack_static = init_ctx_hack_static,
  shutdown = shutdown_ctx, 
  open_ws = open_ws, 
  listen_ws = listen_ws,
  open_tcp = open_tcp,
  listen_tcp = listen_tcp,
  serve_http = serve_http,
  http_get = http_get,
  http_post = http_post,
  Socket = Socket,
  pollnet = pollnet,
  nanoid = get_nanoid,
  sleep_ms = sleep_ms
}