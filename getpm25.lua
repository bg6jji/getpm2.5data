
    Server = "www.pm25.in"
    print("开始内存:"..node.heap())
    tmr.alarm(0, 30000, 1, function()   --请将抓取时间改大一些，减少服务器负载。
     --创建一个TCP连接
     socket=net.createConnection(net.TCP, 0)
     --开始连接服务器
     socket:connect(80, Server)
     socket:on("connection", function(sck) 
      print("connect to:"..Server)
      toget()
      end)

     function toget()
     --HTTP请求头定义

     local ApiKey = "5j1znBVAsnSf5xQyNQyq"     --这个是个共用APIKEY，请换成自己的，没有申请的，请到www.pm25.in申请。API说明请看http://www.pm25.in/api_doc
     local city = "zhengzhou"                  --获取城市
     local station_code = "1321A"              --采样点编号
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
          tempdata = nil
          local aqidata=string.sub(Aqijson,(string.find(Aqijson,"aqi")+5),(string.find(Aqijson,"area")-3))
          local pm25=string.sub(Aqijson,(string.find(Aqijson,"pm2_5")+7),(string.find(Aqijson,"pm2_5_24h")-3))
          local pn=string.sub(Aqijson,(string.find(Aqijson,"position_name")+16),(string.find(Aqijson,"primary_pollutant")-4))
          local Tm=string.find(Aqijson,"time_point")
          local time1=string.sub(Aqijson,(Tm+13),(Tm+32))
          print("综合:"..aqidata.."PM2.5:"..pm25.."监测点:"..pn.."监测时间:"..time1)
          print(node.heap())
      end
      socket:close()
      end)
     --socket:on("disconnection", function(conn, pl) print("disconnection from:"..Server) socket:close() end) 
   end)
