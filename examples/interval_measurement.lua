local mg     = require "moongen"
local memory = require "memory"
local device = require "device"

-- Amir: Instead of timestamping, I'm using another library called "interval_timestamping.lua". Currently they are the same but the second one return three values: (latency, tx, rx).   
local ts     = require "interval_timestamping"

local libmoon = require "libmoon"
local filter = require "filter"
local hist   = require "histogram"
local stats  = require "stats"
local timer  = require "timer"
local arp    = require "proto.arp"
local log    = require "log"

-- set addresses here
local DST_MAC		= nil -- resolved via ARP on GW_IP or DST_IP, can be overriden with a string here
local SRC_IP_BASE	= "10.0.0.10" -- actual address will be SRC_IP_BASE + random(0, flows)
local DST_IP		= "10.1.0.10"
local SRC_PORT		= 1234
local DST_PORT		= 319

-- answer ARP requests for this IP on the rx port
-- change this if benchmarking something like a NAT device
local RX_IP		= DST_IP
-- used to resolve DST_MAC
local GW_IP		= DST_IP
-- used as source IP to resolve GW_IP to DST_MAC
local ARP_IP	= SRC_IP_BASE

function configure(parser)
  parser:description("Generate Timestamped UDP traffic. Then try to measure interval time of consecutive packets.jkk")
	parser:argument("txDev", "Device to transmit from."):convert(tonumber)
	parser:argument("rxDev", "Device to receive from."):convert(tonumber)
  parser:argument("logs", "The directory of the log of timing data.")
	parser:option("-r --rate", "Transmit rate in Mbit/s."):default(10000):convert(tonumber)
end
-- Amir: I fixed the packet size for this code.
local size = 128
function master(args)
  -- Here they just named the rx and tx. There is no distinguishing configuration here.
	txDev = device.config{port = args.txDev, rxQueues = 2, txQueues = 2}
	rxDev = device.config{port = args.rxDev, rxQueues = 2, txQueues = 2}
	device.waitForLinks()
	-- max 1kpps timestamping traffic timestamping. Amir: why?
  txDev:getTxQueue(0):setRate(args.rate)
  -- Amir: TODO: Why did they only call slave for the TX side?
  
  -- Here the point at which they sapareted queues for data, timestamping packets, and arp respectievly.
	mg.startTask("timerSlave", txDev:getTxQueue(0), rxDev:getRxQueue(0), size, args.flows, args.logs)
	arp.startArpTask{
		-- run ARP on both ports
		{ rxQueue = rxDev:getRxQueue(1), txQueue = rxDev:getTxQueue(1), ips = RX_IP },
		-- we need an IP address to do ARP requests on this interface
		{ rxQueue = txDev:getRxQueue(1), txQueue = txDev:getTxQueue(1), ips = ARP_IP }
	}
	mg.waitForTasks()
end

local function fillUdpPacket(buf, len)
	buf:getUdpPacket():fill{
		ethSrc = queue,
		ethDst = DST_MAC,
		ip4Src = SRC_IP,
		ip4Dst = DST_IP,
		udpSrc = SRC_PORT,
		udpDst = DST_PORT,
		pktLength = len
	}
end

local function doArp()
	if not DST_MAC then
		log:info("Performing ARP lookup on %s", GW_IP)
		DST_MAC = arp.blockingLookup(GW_IP, 5)
		if not DST_MAC then
			log:info("ARP lookup failed, using default destination mac address")
			return
t	end
	end
	log:info("Destination mac: %s", DST_MAC)
end

function timerSlave(txQueue, rxQueue, size, flows, logs)
	doArp()
	if size < 84 then
		log:warn("Packet size %d is smaller than minimum timestamp size 84. Timestamped packets will be larger than load packets.", size)
		size = 84
	end

  -- Amir: Create an object of timestamper class. Then, inside the loop, we use measureLatancy method to calculate timestamps for each
  -- packet. 
 	local timestamper = ts:newUdpTimestamper(txQueue, rxQueue)
	mg.sleepMillis(1000) -- ensure that the load task is running
	local baseIP = parseIPAddress(SRC_IP_BASE)
  local filewrite = io.open(logs, "w") 
  local txCtr = stats:newDevTxCounter(txQueue, "plain")
	local rxCtr = stats:newDevRxCounter(rxQueue, "plain")
  local start, stop, duration
	while mg.running() do
    start = libmoon.getTime() 
    local timestamp_result = timestamper:measureLatency(size, function(buf)
                                                                fillUdpPacket(buf, size)
                                                                local pkt = buf:getUdpPacket()
                                                                pkt.ip4.src:set(baseIP)
                                                              end)
    stop = libmoon.getTime()
    duration = stop - start
    -- Amir: I got rid of histogram, and store data in the raw format.
    for i,element in ipairs(timestamp_result) do                                                        
       filewrite:write(element)
       if (i==#timestamp_result) then
          filewrite:write(", ") 
          filewrite:write(duration)
          filewrite:write("\n")
       else
          filewrite:write(", ")
        end
     end
     -- Amir: To measure the rate of timestamped traffic.    
     txCtr:update()
     rxCtr:update()
	end
  txCtr:finalize()
  rxCtr:finalize()
  filewrite:close()
end

