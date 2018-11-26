#!/usr/bin/env ruby

require 'openssl'
require 'base64'

module Rdpcmd

class Remmina
	def genconfig(opts={})
		conf=templateconfig
		conf.gsub!("{{server}}",opts.fetch('server','127.0.0.1'))
		conf.gsub!("{{username}}",opts.fetch('username','user'))
		conf.gsub!("{{domain}}",opts.fetch('domain',''))

		password=opts.fetch('password','')
		conf.gsub!("{{password}}",encrypt_password(password))

		return conf
	end

	def templateconfig()
		<<-HEREDOC
[remmina]
disableclipboard=0
ssh_auth=0
clientname=
quality=0
ssh_charset=
ssh_privatekey=
sharesmartcard=0
resolution=1024x768
group=
password={{password}}
name={{server}}
ssh_loopback=0
shareprinter=0
ssh_username=
ssh_server=
security=
protocol=RDP
execpath=
sound=off
exec=
ssh_enabled=0
username={{username}}
sharefolder=
console=0
domain={{domain}}
server={{server}}
colordepth=8
window_maximize=0
window_height=1041
window_width=956
viewmode=1
HEREDOC
	end
	
	def readconfig()
		confdir=ENV['HOME']+"/"+'.remmina/'
		conffile=confdir+'remmina.pref'
		secret=nil

		input= File.new(conffile, "r")

		input.each do |line|
			if (line =~ /^secret=/)  then
				secini=line.split("=",2)
				secret=secini[1]
				break
			end
		end

		input.close

		unless secret.nil? then
			secret64=Base64.decode64(secret)
			@key=secret64[0..23]
			@iv=secret64[24..48]
		end
	end

	def encrypt_password (password)
		cipher = OpenSSL::Cipher::Cipher.new('DES3')
		cipher.encrypt
		cipher.iv=@iv
		cipher.key=@key
		cipher.padding=0
		strpad=password+"\0"*(8-password.length%8)
		str=strpad.encode("ascii")
		enc=cipher.update(str)+cipher.final
		b64=Base64.encode64(enc)
		return b64.chomp
	end
end

end
