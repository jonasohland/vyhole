block = newDS()
allow = newDS()

function preresolve(dq)
	if allow:check(dq.qname) or (not block:check(dq.qname)) then
		return false
	end

	dq.rcode = pdns.NXDOMAIN
	return true
end

block:add(dofile("/config/vyhole/out/block.lua"))
allow:add(dofile("/config/vyhole/out/allow.lua"))
