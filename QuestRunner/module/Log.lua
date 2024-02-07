local Logger = {
	level = 1,
}
function Logger.setLevel(level)
	if level == "trace" then
		Logger.level = 3
	elseif level == "debug" then
		Logger.level = 2
	elseif level == "error" then
		Logger.level = 1
	elseif level == "suppress" then
		Logger.level = 0
	else
		print("Log level not supported", level)
	end
end
function printLevel(level, ...)
	if Logger.level >= level then
		print("¥", ...)
	end
end
function errorLog(...)
	printLevel(1, "Error:", ...)
end
function log(...)
	printLevel(2, ...)
end
function trace(...)
	printLevel(3, "Trace:", ...)
end

return { log, errorLog, trace, Logger }
