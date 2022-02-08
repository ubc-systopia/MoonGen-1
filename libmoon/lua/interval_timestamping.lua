--- Hardware timestamping.
local mod = {}

local ffi    = require "ffi"
local dpdkc  = require "dpdkc"
local dpdk   = require "dpdk"
local device = require "device"
local eth    = require "proto.ethernet"
local memory = require "memory"
local timer  = require "timer"
local log    = require "log"
local filter = require "filter"
local libmoon = require "libmoon"
local stats = require 
local timestamper = {}
timestamper.__index = timestamper

--- Create a new timestamper.
--- A NIC can only be used by one thread at a time due to clock synchronization.
--- Best current pratice is to use only one timestamping thread to avoid problems.
function mod:newTimestamper(txQueue, rxQueue, mem, udp, doNotConfigureUdpPort)
	mem = mem or memory.createMemPool(function(buf)
		-- defaults are good enough for us here
		if udp then
			buf:getUdpPtpPacket():fill{
				ethSrc = txQueue,
			}
		else
			buf:getPtpPacket():fill{
				ethSrc = txQueue,
			}
		end
	end)
	txQueue:enableTimestamps()
	rxQueue:enableTimestamps()
 
  -- TODO: adding stat fucntion to keep track of data transmitted.
  --  txCtr = stats:newDevTxCounter(h 


	if udp and rxQueue.dev.supportsFdir then
		rxQueue:filterUdpTimestamps()
	elseif not udp then
		rxQueue:filterL2Timestamps()
	end
  return setmetatable({
		mem = mem,
		txBufs = mem:bufArray(1),
		rxBufs = mem:bufArray(128),
		txQueue = txQueue,
		rxQueue = rxQueue,
		txDev = txQueue.dev,
		rxDev = rxQueue.dev,
		seq = 1,
		udp = udp,
		useTimesync = rxQueue.dev.useTimsyncIds,
		doNotConfigureUdpPort = doNotConfigureUdpPort
	}, timestamper)
end

--- See newTimestamper()
function mod:newUdpTimestamper(txQueue, rxQueue, mem, doNotConfigureUdpPort)
	return self:newTimestamper(txQueue, rxQueue, mem, true, doNotConfigureUdpPort)
end

--- Try to measure the latency of a single packet.
--- @param pktSize optional, the size of the generated packet, optional, defaults to the smallest possible size
--- @param packetModifier optional, a function that is called with the generated packet, e.g. to modified addresses
--- @param maxWait optional (cannot be the only argument) the time in ms to wait before the packet is assumed to be lost (default = 15)
function timestamper:measureLatency(pktSize, packetModifier, maxWait)
  local start, stop, duration
  start = libmoon.getTime()
	if type(pktSize) == "function" then -- optional first argument was skipped
		return self:measureLatency(nil, pktSize, packetModifier)
	end
	pktSize = pktSize or self.udp and 76 or 60
  -- Amir: Time we wait until receive a response or declare packet as a lost packet.
	maxWait = (maxWait or 15) / 1000

  -- Amir: Allocating memory with size of one packet to transmit.
	self.txBufs:alloc(pktSize)
	local buf = self.txBufs[1]


  -- Amir: This function works with dpdk to enable ieee 1588 which is a protocol for timming measurements available on the nic.
  -- function pkt:enableTimestamps()
	--   self.ol_flags = bit.bor(self.ol_flags, dpdk.PKT_TX_IEEE1588_TMST)
  -- end
	buf:enableTimestamps()


  -- Amir: The measureLatency function is a method for timestamper class. Here we just update the sequence number for the 
  -- whole class.
	local expectedSeq = self.seq
	self.seq = (self.seq + 1) % 2^16
	if self.udp then
		buf:getUdpPtpPacket().ptp:setSequenceID(expectedSeq)
	else
		buf:getPtpPacket().ptp:setSequenceID(expectedSeq)
	end

  -- Amir: The packet modifier is a callback function passed to the this function if we want to modify timestamping packet before
  -- seding it out.
	local skipReconfigure
	if packetModifier then
		skipReconfigure = packetModifier(buf)
	end

  -- Amir: seems to be regular checking. 
	if self.udp then
		if not self.doNotConfigureUdpPort then
			-- change timestamped UDP port as each packet may be on a different port
			self.rxQueue:enableTimestamps(buf:getUdpPacket().udp:getDstPort())
		end
		buf:getUdpPtpPacket():setLength(pktSize)
		self.txBufs:offloadUdpChecksums()
		if self.rxQueue.dev.reconfigureUdpTimestampFilter and not skipReconfigure then
			-- i40e driver fdir filters are broken
			-- it is not possible to match on flex bytes in udp packets without matching IPs and ports as well
			-- so we have to look at that packet and reconfigure the filters
			self.rxQueue.dev:reconfigureUdpTimestampFilter(self.rxQueue, buf:getUdpPacket())
		end
	end
  stop = libmoon.getTime()
  duration = stop - start 
  local block_1 = duration
  start = libmoon.getTime() 
  -- Amir: It is the resynchronization procedure they mentioned in the paper. It's been done using dpdk functionalities. 
	mod.syncClocks(self.txDev, self.rxDev)

	-- clear any "leftover" timestamps
	self.rxDev:clearTimestamps()

  -- Amir: here we just send one packet. Becaues the size of txBufs is determined as one in the timestamper metatable.
	self.txQueue:send(self.txBufs)
  -- TODO: I added stat records here to maintain information about amount of data that is send through this queue.
  --self.txCtr:update()
  --self.rxCtr:update()



  -- Amir: The function description says: "Read a TX timestamp from the device". However it actually uses the following call to the
  -- DPDK to make it available:
  -- dpdkc.rte_eth_timesync_read_tx_timestamp(self.id, ts)
  -- The input of this function is amount of time ,in milissecond, it waits for function to be run (i.e. timestamp packet).
	local tx = self.txQueue:getTimestamp(500)
	local numPkts = 0
	if tx then
		-- sent was successful, try to get the packet back (assume that it is lost after a given delay)
		local timer = timer:new(maxWait)

    -- Amir: This is the time the code waits to receive a response from the receiver. This is not the same as previous timer...
  stop = libmoon.getTime()
  duration = stop - start  
  local block_2 = duration
  while timer:running() do
      start = libmoon.getTime()
      -- Amir: It waits for 1000 ms to receive something. it uses dpdk calls to pull NIC queues.
      -- It doesn't make sense for me why we might have receive more than one packet when we only have sent one timestampped packet.
			local rx = self.rxQueue:tryRecv(self.rxBufs, 1000)
			numPkts = numPkts + rx
      
      -- Amir: Check whether the NIC has time stamp or not... 
			local timestampedPkt = self.rxDev:hasRxTimestamp()
			if not timestampedPkt then
				-- NIC didn't save a timestamp yet, just throw away the packets
				self.rxBufs:freeAll()
			else
				-- received a timestamped packet (not necessarily in this batch)
				for i = 1, rx do
					local buf = self.rxBufs[i]
					local timesync = self.useTimesync and buf:getTimesync() or 0
					local seq = (self.udp and buf:getUdpPtpPacket() or buf:getPtpPacket()).ptp:getSequenceID()
					if buf:hasTimestamp() and seq == expectedSeq and (seq == timestampedPkt or timestampedPkt == -1) then
						-- yay!
						local rxTs = self.rxQueue:getTimestamp(nil, timesync) 
						if not rxTs then
							-- can happen if you hotplug cables
							return nil, numPkts
						end
						self.rxBufs:freeAll()
           
            stop = libmoon.getTime()
            duration =   stop - start 
            local block_3 = duration

						local lat_a = rxTs - tx
            local lat = {lat_a, tx, rxTs,block_1, block_2, block_3}
						if lat_a > 0 and lat_a < 2 * maxWait * 10^9 then
							-- negative latencies may happen if the link state changes
							-- (timers depend on a clock that scales with link speed on some NICs)
							-- really large latencies (we only wait for up to maxWait ms)
							-- also sometimes happen since changing to DPDK for reading the timing registers
							-- probably something wrong with the DPDK wraparound tracking
							-- (but that's really rare and the resulting latency > a few days, so we don't really care)
							return lat, numPkts
						else
							return nil, numPkts
						end
					elseif buf:hasTimestamp() and (seq == timestampedPkt or timestampedPkt == -1) then
						-- we got a timestamp but the wrong sequence number. meh.
						self.rxQueue:getTimestamp(nil, timesync) -- clears the register
						-- continue, we may still get our packet :)
					elseif seq == expectedSeq and (seq ~= timestampedPkt and timestampedPkt ~= -1) then
						-- we got our packet back but it wasn't timestamped
						-- we likely ran into the previous case earlier and cleared the ts register too late
						self.rxBufs:freeAll()
						return nil, numPkts
					end
				end
			end
		end
		-- looks like our packet got lost :(
		return nil, numPkts
	else
		-- happens when hotplugging cables
		log:warn("Failed to timestamp packet on transmission")
		timer:new(maxWait):wait()
		return nil, numPkts
	end
end


function mod.syncClocks(dev1, dev2)
	local regs1 = dev1.timeRegisters
	local regs2 = dev2.timeRegisters
	if regs1[1] ~= regs2[1]
	or regs1[2] ~= regs2[2]
	or regs1[3] ~= regs2[3]
	or regs1[4] ~= regs2[4] then
		log:fatal("NICs incompatible, cannot sync clocks")
	end
	dpdkc.libmoon_sync_clocks(dev1.id, dev2.id, unpack(regs1))
	-- just to tell the driver that we are resetting the clock
	-- otherwise the cycle tracker becomes confused on long latencies
	dev1:resetTimeCounters()
	dev2:resetTimeCounters()
end

return mod

