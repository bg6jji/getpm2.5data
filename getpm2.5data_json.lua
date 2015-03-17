
    -- 果云测试板IO设备映射表 Test board IO MAP
    -- 8 RED 7 GREEN 6 BLUE LED 5 LED 0 RELAY 2 BEEP 1 DHT11 3 SW2 4 SW3
    --此版本需要20150317json版本
    Server = "www.pm25.in"
    gpio.mode(5,gpio.OUTPUT)    --LED
    --gpio.mode(0,gpio.OUTPUT)    --继电器
    -- gpio.mode(2,gpio.OUTPUT)    --蜂鸣器
    
    gpio.write(5,gpio.LOW)
    --gpio.write(0,gpio.LOW)
    -- gpio.write(2,gpio.LOW)

    -- pwm.setup(8, 500, 512)  pwm.setup(7, 500, 512)  pwm.setup(6, 500, 512) 
    -- pwm.start(8)            pwm.start(7)            pwm.start(6)  

    -- function led(r,g,b) 
    -- pwm. setduty(8,r)       pwm. setduty(7,g)       pwm. setduty(6,b)    end 
    -- led(0, 0, 0) -- led关闭显示
    function ledflash(flashtime)
      local lighton=0
      local cnt=1
      tmr.alarm(1,200,1,function()
        if lighton==0 then 
            lighton=1 
            gpio.write(5,gpio.HIGH) 
        else 
            lighton=0 
            gpio.write(5,gpio.LOW) 
        end 
        if cnt >= flashtime*2 then tmr.stop(1) else cnt=cnt+1 end
      end)
    end

    print("开始内存:"..node.heap())
    tmr.alarm(0, 30000, 1, function()   --请将抓取时间改大一些，减少服务器负载。
     --创建一个TCP连接
     socket=net.createConnection(net.TCP, 0)
     socket:dns(Server, function(conn,ip) if ip == nil then print("DNS Fail.") node.restart() end end)
     --开始连接服务器
     socket:connect(80, Server)
     socket:on("connection", function(sck) 
      print("connect to:"..Server)
      toget()
      end)

     function toget()
     --HTTP请求头定义

     local ApiKey = "XXXXX"     --这个是个共用APIKEY，请换成自己的，没有申请的，请到www.pm25.in申请。API说明请看http://www.pm25.in/api_doc
     --local city = "XXXX"                  --获取城市
     local station_code = "XXXXX"              --采样点编号
     socket:send("GET /api/querys/aqis_by_station.json?station_code="..station_code..  --"&city="..city..
            "&token="..ApiKey.." HTTP/1.1\r\n" ..    --这里只是获取某个监测点的数据
            "Host: www.pm25.in\r\n" ..
            "Accept: */*" ..
            "User-Agent: Nodemcu\r\n\r\n")
     end

     --HTTP响应内容
     socket:on("receive", function(sck, response)
     --print(response)
      if string.find(response,"error\"") then print("Error and Restart System in 3min。") tmr.delay(3*60*1000*1000) print("Restarting...") node.restart() end
      local tempdata=string.find(response,"aqi\"")
     
      if tempdata then
          local Aqijson=string.sub(response,tempdata-2,string.len(response)-1)
          tempdata = nil response = nil
          local cjson = require "cjson"
          local Value = cjson.decode(Aqijson)
          cjson = nil Aqijson = nil
          local aqidata = Value["aqi"]
          local aqilevel = (aqidata-aqidata%50)/50
          if aqidata%50 then aqilevel=aqilevel+1 end
          if aqidata>300 then aqilevel = 6 elseif aqidata > 200 then aqilevel = 5 end   --辅助分级计算，5、6级范围较大
          print("AQI:"..aqidata.." 污染等级:"..aqilevel)    --"  PM10:"..pm10.."  PM2.5:"..pm25..
          print(node.heap())
          ledflash(aqilevel)   --按污染等级的数字闪烁，这样清楚知道几级污染。
          aqidata = nil Value = nil
          if node.heap() < 4000 then node.restart() end
          
      end
      socket:close()
      end)
   end)

--[{"aqi":95,"area":"郑州","co":1.065,"co_24h":0.901,"no2":37,"no2_24h":40,"o3":57,"o3_24h":60,"o3_8h":26,"o3_8h_24h":58,"pm10":137,"pm10_24h":118,"pm2_5":71,"pm2_5_24h":44,"position_name":"四十七中","primary_pollutant":"细颗粒物(PM2.5)","quality":"良"so2":33,"so2_24h":21,"station_code":"1321A","time_point":"2015-03-10T13:00:00Z"}]

