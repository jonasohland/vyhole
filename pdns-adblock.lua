deny = newDS()
allow = newDS()

deny:add(dofile("/config/vyhole/out/deny.lua"))
allow:add(dofile("/config/vyhole/out/allow.lua"))

function preresolve(dq)
	if allow:check(dq.qname) or (not deny:check(dq.qname)) then
		return false
	end

	pdnslog("blocked " .. dq.qname:toString())

	dq.rcode = pdns.NXDOMAIN
	return true
end
