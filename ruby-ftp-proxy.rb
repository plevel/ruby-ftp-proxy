require 'net/ftp'
require 'base64'


module Net
  module FTPProxy
    ENDLINE = "\r\n"
    class FTP
      attr_accessor :soc
      def initialize(phost, pport, puser, ppass)
        @soc = TCPSocket.new(phost,pport)
        str=@soc.readline
        if str !=~ /^220/
          raise "Invalid proxy response"
        end
        @soc.write "USER " + puser
        @soc.write(ENDLINE)
        str=@soc.readline
        if str =~ /^331/
          # password required
          @soc.write "PASS " + ppass
          @soc.write(ENDLINE)
          str=@soc.readline
        end
        
        unless str =~ /^230/
          raise "proxy user or password not correct (#{str})"
        end
      end
      
      def connect(host, port=21, &block)
        @soc.write("SITE #{host}:#{port}")
        @soc.write(ENDLINE)
        ftp = Net::FTP.new()
        ftp.set_socket(@soc)
        if block_given?
          yield(ftp)
        else
          return ftp
        end
      end
    end
    
    class HTTPConnect
      attr_accessor :soc, :puser, :ppass
      def initialize(phost, pport, puser, ppass)
        @soc = TCPSocket.new(phost,pport)
        @puser, @ppass = puser, ppass
      end
      
      def connect(host, port=21, &block)
        @soc.write("CONNECT #{host}:#{port} HTTP/1.1")
        @soc.write(ENDLINE)
        @soc.write("Host #{host}:#{port}")
        @soc.write(ENDLINE)
        
        
        if(@puser&&@ppass)
          header = "Proxy-Authorization: Basic " + Base64.encode64(@puser+":"+@ppass)
          @soc.write(header)
          @soc.write(ENDLINE)
        end
        @soc.write(ENDLINE)
        
        resp=[]
        str=@soc.readline
        
        resp<<str
        while(str!="")
          resp<<str
          str=@soc.readline.strip
        end
        
        if resp[0] =~ /200/
          ftp = Net::FTP.new()
          ftp.set_socket(@soc)
          if block_given?
            yield(ftp)
          else
            return ftp
          end
        else
          raise "Error occured: "+resp.join("\n")
        end
      end
      
    end
  end
end
