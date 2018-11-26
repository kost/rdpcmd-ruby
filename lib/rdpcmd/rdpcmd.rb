#!/usr/bin/env ruby

module Rdpcmd

class Rdpcmd
	def initialize(params={})
		@log=params.fetch('log','')
	end

	def wait4window(pid,ip)
		waitfor=5
		wid=nil

		waitfor.times do |i|
			@log.debug("Waiting for Remmina to start: #{i}")
			f = IO.popen("xdotool search --all --pid #{pid} --name #{ip}")
			# puts f.readlines
			idline=''
			f.each do |line|
				@log.debug("Parsed xdotool line: #{line}")
				idline=line
			end
			unless idline.to_s.strip.empty? then
				wid=idline.chomp
				@log.debug("Taking wid: #{wid}")
				f.close
				break
			end
			f.close
			sleep(1)
		end
		@wid=wid
		return wid
	end

	def systeml(str)
		@log.debug(str)
		system(str)
	end

	def connect (opts={})
		rem=Remmina.new
		rem.readconfig

		@log.debug("Connecting to IP: #{opts['server']} with user #{opts['username']} and domain #{opts['domain']}")
		tempconfig=rem.genconfig(opts)

		@t = Tempfile.new(["rdpcmd",".remmina"])
		@t.write(tempconfig)
		@t.close

		cmdspawn="remmina -c #{@t.path}"
		@log.debug("Spawning Remmina with cmdline: #{cmdspawn}")

		@pid=Process.spawn(cmdspawn)

		@log.debug("Spawned Remmina with PID: #{@pid}")

		sleepfor=3
		@log.debug("Sleeping for #{sleepfor}")
		sleep(sleepfor)

		wait4window(@pid,opts['server'])
		if @wid.nil? then
			@log.error("Cannot find Remmina window, is Remmina and xdotool installed? Connection problem.")
			return false
		end

		@log.debug("Remmina contacted, window ID: #{@wid}")

	end

	def terminate()
		@t.unlink
		@log.debug("Killing Remmina with PID: #{@pid}")
		Process.kill("KILL", @pid)
	end

	def prepareremmina()
		systeml("xdotool windowactivate --sync #{@wid} key --clearmodifiers 'Control_R'")
	end

	def startrun(cmd)
		systeml("xdotool windowactivate --sync #{@wid} key 'Super+r' sleep 2 type '#{cmd}'")
		systeml('xdotool key --clearmodifiers "Return"')
	end

	def startrunele(sleepfor=4)
		startrun("powershell Start-Process cmd -Verb runAs")
		systeml("xdotool sleep 3 key 'Alt+y' sleep #{sleepfor}")
	end

	def closecmd(sleepfor)
		@log.debug("Sleeping for final things to settle")
		sleep sleepfor
		systeml("xdotool type 'exit'")
		systeml('xdotool key --clearmodifiers "Return"')
	end

	def cleanupremmina()
		systeml("xdotool windowactivate --sync #{@wid} key --clearmodifiers 'Control_R'")
		@log.debug("Sleeping for final things to settle")
		sleep 1
	end

	def sendline(cmd)
		systeml("xdotool type '#{cmd}'")
		systeml('xdotool key --clearmodifiers "Return"')
	end

	def sendkeys(keys,clearmod=false)
		opts=''
		if clearmod then
			opts << " --clearmodifiers "
		end
		systeml("xdotool key #{opts} #{keys}")
	end

	def sendfile(file, sleepfor=0.5) 
		input= File.new(file, "r")
		input.each do |line|
			sendline(line)
			sleep(sleepfor)
		end
		input.close
	end

	def copyfile(src,dest,sleepfor=0.5) 
		sendline("copy con #{dest}")
		sleep(sleepfor)
		sendfile(src, sleepfor)
		sleep(sleepfor)
		systeml('xdotool key --clearmodifiers "Ctrl+Z" "Return"')
	end

	def singleElevated(cmd,toexit=0) 
		prepareremmina()
		startrunele()
		sendline(cmd)
		if toexit > 0 then
			closecmd(toexit)
		end
		cleanupremmina()
	end

	def singleNormal(cmd,toexit=0) 
		prepareremmina()
		startrun('cmd.exe')
		sendline(cmd)
		if toexit > 0 then
			closecmd(toexit)
		end
		cleanupremmina()
	end
end

end
