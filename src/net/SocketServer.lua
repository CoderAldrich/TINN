
local ffi = require("ffi");

local Application = require("Application");
local NativeSocket = require("NativeSocket");
local ws2_32 = require("ws2_32");


Application:setMessageQuanta(5);

local SocketServer = {}
setmetatable(SocketServer, {
  __call = function(self, ...)
    return self:create(...);
  end,
});

local SocketServer_mt = {
  __index = SocketServer;
}

SocketServer.init = function(self, socket, onAccept)
--print("SocketServer.init: ", socket, onAccept, onAcceptParam)
  local obj = {
    ServerSocket = socket;
    OnAccept = onAccept;
  };

  setmetatable(obj, SocketServer_mt);

  return obj;
end

SocketServer.create = function(self, port, onAccept, autoclose)
  autoclose = autoclose or false;
  port = port or 9090;
--print("SocketServer:create(): ", port, onAccept);

  local socket, err = NativeSocket:createServer({port = port, backlog = 150, autoclose = autoclose})
	
  if not socket then 
    print("Server Socket not created!!")
    return nil, err
  end

  return self:init(socket, onAccept);
end


function SocketServer.handleAccepted(self, sock)
--print("SocketServer.handleAccepted(): ", sock);

  if self.OnAccept then
    --print("SocketServer.handleAccepter, CALLING self.OnAccept: ", sock)
    return self.OnAccept(sock);
  else
--print("NO OnAccept available, closing  socket...")
    ws2_32.closesocket(sock);
  end
end

-- The primary application loop
SocketServer.loop = function(self)

  while true do
    local sock, err = self.ServerSocket:accept();

    --print("SocketServer.loop, Accepted: ", sock, err)
    
    if sock then
      self:handleAccepted(sock);
    else
       print("Accept ERROR: ", err);
    end

    --collectgarbage();
  end
end

SocketServer.run = function(self)
  --print("SocketServer.run()");
  spawn(self.loop, self);
  Application:run();
end

return SocketServer;
