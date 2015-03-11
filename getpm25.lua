
    -- 果云测试板IO设备映射表 Test board IO MAP
    -- 8 RED 7 GREEN 6 BLUE LED 5 LED 0 RELAY 2 BEEP 1 DHT11 3 SW2 4 SW3

    Server = "www.pm25.in"
    gpio.mode(5,gpio.OUTPUT)    --LED
    --gpio.mode(0,gpio.OUTPUT)    --继电器
    gpio.mode(2,gpio.OUTPUT)    --蜂鸣器
    
    gpio.write(5,gpio.LOW)
    --gpio.write(0,gpio.LOW)
    gpio.write(2,gpio.LOW)

    delay = tmr.delay

    pwm.setup(8, 500, 512)  pwm.setup(7, 500, 512)  pwm.setup(6, 500, 512) 
    pwm.start(8)  pwm.start(7)  pwm.start(6)  

    function led(r,g,b) 
    pwm. setduty(6,g)  pwm. setduty(7,b)  pwm. setduty(8,r)  end 
    led(0, 0, 0) -- led关闭显示

    function ledflash(flashtime)
      gpio.write(5,gpio.HIGH) delay(flashtime*1000) gpio.write(5,gpio.LOW) delay(flashtime*1000)
      gpio.write(5,gpio.HIGH) delay(flashtime*1000) gpio.write(5,gpio.LOW) delay(flashtime*1000)
    end

    print("开始内存:"..node.heap())
    tmr.alarm(0, 30000, 1, function()   --请将抓取时间改大一些，减少服务器负载。
     --创建一个TCP连接
     socket=net.createConnection(net.TCP, 0)
     --socket:dns(Server, function(conn,ServerIP) ServerIP = ip end)
     --开始连接服务器
     socket:connect(80, Server)
     socket:on("connection", function(sck) 
      print("connect to:"..Server)
      toget()
      end)

     function toget()
     --HTTP请求头定义

     local ApiKey = "xxxxxx"     --这个是个共用APIKEY，请换成自己的，没有申请的，请到www.pm25.in申请。API说明请看http://www.pm25.in/api_doc
     local city = "xxxx"                  --获取城市
     local station_code = "xxxx"              --采样点编号
     socket:send("GET /api/querys/aqis_by_station.json?city="..city.."&station_code="..station_code.."&token="..ApiKey.." HTTP/1.1\r\n" ..    --这里只是获取某个监测点的数据
            "Host: www.pm25.in\r\n" ..
            "Accept: */*" ..
            "User-Agent: Nodemcu\r\n\r\n")
     end

     --HTTP响应内容
     socket:on("receive", function(sck, response)
     --print(response)
     local tempdata=string.find(response,"aqi\"")
   
      if tempdata then
          local Aqijson=string.sub(response,tempdata)
          tempdata = nil response = nil
          local aqidata=string.sub(Aqijson,(string.find(Aqijson,"aqi")+5),(string.find(Aqijson,"area")-3))
          local pm10=string.sub(Aqijson,(string.find(Aqijson,"pm10")+6),(string.find(Aqijson,"pm10_24h")-3))
          local pm25=string.sub(Aqijson,(string.find(Aqijson,"pm2_5")+7),(string.find(Aqijson,"pm2_5_24h")-3))
          local pn=string.sub(Aqijson,(string.find(Aqijson,"position_name")+16),(string.find(Aqijson,"primary_pollutant")-4))
          local Tm=string.find(Aqijson,"time_point")
          local time1=string.sub(Aqijson,(Tm+13),(Tm+32))  
          tm = nil  Aqijson = nil
          print("综合:"..aqidata.."  PM10:"..pm10.."  PM2.5:"..pm25)
          print("监测点:"..pn.."  监测时间:"..time1)
          print(node.heap())
          aqidata = tonumber(aqidata) pm10 = tonumber(pm10) pm25 = tonumber(pm25)
          led(aqidata, pm10, pm25)    --LED按数值点亮，越亮污染越重
          if aqidata >= 200 then          ledflash(2000)
            elseif aqidata >= 150 then    ledflash(1000) 
               elseif aqidata >= 100 then ledflash(500) end
          
          
      end
      socket:close()
      end)
     --socket:on("disconnection", function(conn, pl) print("disconnection from:"..Server) socket:close() end) 
   end)
