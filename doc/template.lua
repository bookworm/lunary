module(..., package.seeall)

function print(...)
	local t = {...}
	for i=1,select('#', ...) do
		t[i] = tostring(t[i])
	end
	io.write(table.concat(t, '\t')..'\n')
end

