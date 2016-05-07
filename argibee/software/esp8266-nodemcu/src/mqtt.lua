print("MQTT WORKER")

dofile("device-id.lua");

--PIN PORT THAT CONTROLS LAMP
local lampPin = 4; --GPIO2 on ESP8266
gpio.mode(lampPin, gpio.OUTPUT);

local baseTopic = "flaviostutz/cozme/devices/alarm/" .. deviceId;

m = mqtt.Client("clientid", 30, "", "")

print("Configuring lastwill")
m:lwt(baseTopic .. "/status", "{'situation':'offline'}", 0, 1)

print("Connecting to mqtt server")
m:connect("test.mosquitto.org", 1883, 0, function(conn) 
    print("--connected")

    print("Subscribing to topic " .. baseTopic .. "/lamp-state")
    m:subscribe(baseTopic .. "/lamp-state",0, function(conn) 
        print("--subscribe success") 
    end)

    print("Subscribing to topic " .. baseTopic .. "/maintenance")
    m:subscribe(baseTopic .. "/maintenance",0, function(conn) 
        print("--subscribe success") 
    end)

    print("Configuring onmessage")
    m:on("message", function(conn, topic, data) 
       print(topic .. ":" ) 
       if data ~= nil then
          print(data)
          local ok, msg = pcall(cjson.decode, data);
          if(ok) then
              print("Message fields:");
              for k, v in pairs(msg) do
                 print(k, v)
              end
          
              if(topic == baseTopic .. "/lamp-state") then
                 if(msg.pattern ~= nil and msg.interval ~= nil) then
                    print("LAMP STATE RECEIVED: pattern=" .. msg.pattern .. "; interval=" .. msg.interval);
                    animateLamp(msg.pattern, msg.interval);
                 else
                    print("WARN: lamp-state message received but no pattern/interval defined. ignoring.");
                 end
              
              elseif(topic == baseTopic .. "/maintenance") then
                 if(msg.command ~= nil) then
                    if(msg.command == "restart") then
                       print("RESTARTING UNIT");
                       node.restart();
                    elseif(msg.command == "factory-reset") then
                       print("PERFORMING FACTORY RESET");
                       wifi.sta.autoconnect(0);
                       node.restart();
                    end
                 else
                    print("WARN: maintenance message received but no command specified. igoring.");
                 end
              end
              
           else
              print("Error parsing json. err=" .. msg);
           end
       end
    end)

    print("Starting 'status' interval timer");
    publishStatusMessage();
    tmr.interval(0, 120000, publishStatusMessage);
end)

function publishStatusMessage()
    print("Publishing status message")
    m:publish(baseTopic .. "/status","{'situation','online'}",0,1, function(conn) 
        print("--status sent") 
    end)
end

function animateLamp(pattern,interval)
   print("TODO: ANIMATE LAMP HERE ACCORDING TO PATTERN!");
   gpio.write(lampPin, gpio.HIGH);
   tmr.delay(500 * 1000);
   gpio.write(lampPin, gpio.LOW);
   tmr.delay(500 * 1000);
end
